import Libc


extension File {
	
	public func load(
	) throws -> Binary {
		let path: String = self.path.expanded
		
		let handle = Self.retryInterrupted {
			open(path, O_RDONLY)
		}
		
		guard handle != -1
						else { throw FileSystemError.missing(self) }
		
		defer {
			close(handle)
		}
		
		var status = stat()
		
		let statResult = Self.retryInterrupted { fstat(handle, &status) }
		guard statResult != -1
						else { throw FileSystemError.missing(self) }
		
		guard status.st_mode & S_IFMT == S_IFREG
		else { throw FileSystemError.invalidType(self) }
		
		return try Self.readAll(reservingCapacity: Int(status.st_size)) {
			Libc.read(handle, $0, $1)
		}
	}
	
	@inlinable
	public func save(
		_ binary: Binary,
		atomic: Bool = false,
	) throws {
		if atomic {
			try saveAtomically(binary)
		}
		else {
			try saveNormally(binary)
		}
	}
	
	public func saveNormally(
		_ binary: Binary,
	) throws {
		let path: String = self.path.expanded
		
		touchDirectory()
		
		let handle = Self.retryInterrupted {
			open(
				path,
				O_WRONLY | O_CREAT | O_TRUNC,
				FilePermissions(owner: .readWrite, group: .read, other: .read).mode,
			)
		}
		
		try POSIX.checkError(
			handle
		) { $0 != -1 }
		
		defer {
			close(handle)
		}
		
		try Self.writeAll(binary) {
			Libc.write(handle, $0, $1)
		}
	}
	
	/// 同じディレクトリの一時ファイルへ書き込み、保存先をアトミックに置き換える。
	/// 既存の通常ファイルのアクセス権を引き継ぎ、新規ファイルは0600で作成する。
	/// シンボリックリンクはリンク自体を置き換える。ディスクへの同期は行わない。
	public func saveAtomically(
		_ binary: Binary,
	) throws {
		try saveAtomically(
			binary,
		) {
			Libc.write($0, $1, $2)
		}
	}
	
	// 書き込みを差し替えられるようにし、ディスク容量不足などの失敗も検証する。
	func saveAtomically(
		_ binary: Binary,
		using write: (Int32, UnsafeRawPointer, Int) -> Int,
	) throws {
		let destination: FilePath
		= TemporaryPath.absolute(path)

		try destination.parent.directory.createDirectory()
		
		var status = stat()
		let result = Self.retryInterrupted { lstat(destination.asString, &status) }
		var permissions: FilePermissions?
		
		if result == -1 {
			let error = errno
			guard error == ENOENT else { throw POSIXError.system(error) }
		}
		else {
			switch status.st_mode & S_IFMT {
			case S_IFREG:
				permissions = FilePermissions(mode: status.st_mode)
			case S_IFLNK:
				break
			default:
				throw FileSystemError.invalidType(self)
			}
		}
		
		try Self.withTemporaryHandle(
			prefix: ".Basis",
			in: destination.parent.directory,
		) { temporary, handle in
			try Self.writeAll(binary) {
				write(handle, $0, $1)
			}
			
			if let permissions {
				guard
					Self.retryInterrupted(
						{ fchmod(handle, permissions.mode) }
					) == 0
				else { throw POSIXError.system }
			}
			
			// closeの失敗でも保存先を変更しない。記述子を再利用して二重に閉じない。
			let descriptor = handle
			handle = -1
			guard close(descriptor) == 0 else { throw POSIXError.system }
			
			guard
				Self.retryInterrupted(
					{ rename(temporary.path.asString, destination.asString) }
				) == 0
			else { throw POSIXError.system }
		}
	}
	
}


extension File {

	@inlinable
	public func save(
		_ text: String,
		atomic: Bool = false,
	) throws {
		try save(
			text.asBinary,
			atomic: atomic,
		)
	}

	@inlinable
	public func createLink(
		of target: FilePath,
	) throws {
		try POSIX.createLink(
			at: path.expanded,
			of: target.expanded,
		)
	}

	@inlinable
	public func createSymlink(
		of target: FilePath,
	) throws {
		try POSIX.createSymlink(
			at: path.expanded,
			of: target.expanded,
		)
	}
		
	@inlinable
	public func copy(
		to destination: FilePath,
	) throws {
		try POSIX.copyFile(
			at: path.expanded,
			to: destination.expanded,
		)
	}
		
	@inlinable
	public func move(
		to destination: FilePath,
	) throws {
		try POSIX.move(
			at: path.expanded,
			to: destination.expanded,
		)
	}
		
	@inlinable
	public func delete(
	) throws {
		try POSIX.unlink(
			at: path.expanded,
		)
	}	
	
	@inlinable
	public func touchDirectory(
	) {
		try? path.parent.directory.createDirectory()
	}
		
}


extension File {

	static func retryInterrupted(
		_ operation: () -> Int32,
	) -> Int32 {
		while true {
			let result = operation()
			if result == -1 && errno == EINTR { continue }
			return result
		}
	}

	static func readAll(
		reservingCapacity capacity: Int = 0,
		using read: (UnsafeMutableRawPointer, Int) -> Int,
	) throws -> Binary {
		var bytes: [UInt8] = []
		bytes.reserveCapacity(capacity)
		var chunk = [UInt8](repeating: 0, count: 64 * 1024)

		while true {
			let count = chunk.withUnsafeMutableBytes {
				read($0.baseAddress!, $0.count)
			}

			if count < 0 {
				let error = errno
				if error == EINTR { continue }
				throw POSIXError.system(error)
			}
			if count == 0 { return Binary(bytes) }

			bytes.append(contentsOf: chunk.prefix(count))
		}
	}

	static func writeAll(
		_ binary: Binary,
		using write: (UnsafeRawPointer, Int) -> Int,
	) throws {
		try binary.withUnsafeBytes { bytes in
			var offset = 0

			while offset < bytes.count {
				let remaining = min(64 * 1024, bytes.count - offset)
				let count = write(bytes.baseAddress! + offset, remaining)

				if count < 0 {
					let error = errno
					if error == EINTR { continue }
					throw POSIXError.system(error)
				}
				guard count > 0 else { throw POSIXError.system(EIO) }

				offset += count
			}
		}
	}
}
