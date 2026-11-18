import Libc


// MARK: - FileSystem


extension POSIX {

	public static func move(
		at source: String,
		to destination: String,
	) throws {
		if rename(source.asString, destination) != 0 {
			guard errno == EXDEV
			else { throw POSIXError.system }

			try copy(at: source, to: destination)
			try delete(at: source)
		}
	}
	
	public static func copy(
		at source: String,
		to destination: String,
	) throws {
		let status = FileStatus(at: source, followLink: false)
		
		switch status?.type {
			case .file:
				try copyFile(at: source, to: destination)
				
			case .directory:
				try copyDirectory(at: source, to: destination)
				
			case .link:
				try copySymlink(at: source, to: destination)
				
			default:
				break
		}
	}
	
	public static func delete(
		at path: String,
	) throws {
		let status = FileStatus(at: path, followLink: false)
		
		switch status?.type {
			case .directory:
				try deleteDirectory(at: path, recursive: true)
				
			default:
				try unlink(at: path)
		}
	}

	public static func unlink(
		at path: String,
	) throws {
		try POSIX.checkError(
			Libc.unlink(path) == 0
		)
	}
	
}


// MARK: - File Operation


extension POSIX {

	public static func copyFile(
		at source: String,
		to destination: String,
	) throws {
		var fileInfo: stat = .init()
		
		try POSIX.checkError(
			stat(source.asString, &fileInfo) >= 0
		)
		
		let dstfd: Int32 = open(
			destination.asString,
			O_WRONLY | O_CREAT | O_TRUNC,
			FilePermissions(owner: .readWrite, group: .read, other: .read).mode,
		)

		try POSIX.checkError(
			dstfd >= 0,
		)

		defer { close(dstfd) }
		
		// NOTE: Set the file permissions using fchmod() instead of when open()ing to avoid umask() issues
		let permissions: FilePermissions = .init(mode: fileInfo.st_mode)
		try POSIX.checkError(
			fchmod(dstfd, permissions.mode) == 0
		)
		
		if fileInfo.st_size == 0 {
			// NOTE: No copying required
			return
		}
		
		let srcfd: Int32 = open(
			source.asString,
			O_RDONLY,
		)
		try POSIX.checkError(
			srcfd >= 0,
		)

		defer { close(srcfd) }
		
		let buffer: UnsafeMutablePointer<UInt8> = .allocate(capacity: Int(fileInfo.st_blksize))
		defer { buffer.deallocate() }
		
		var bytesRemaining: off_t = fileInfo.st_size
		while bytesRemaining > 0 {
			let bytesToRead: off_t = min(bytesRemaining, off_t(fileInfo.st_blksize))
			
			let bytesRead: Int = try read(
				fd: srcfd,
				buffer: buffer,
				length: Int(bytesToRead),
			)
			
			if bytesRead == 0 {
				// Early EOF
				return
			}
			
			try write(
				fd: dstfd,
				buffer: buffer,
				length: bytesRead,
			)
			
			bytesRemaining -= off_t(bytesRead)
		}
	}
	
	public static func read(
		fd: Int32,
		buffer: UnsafeMutablePointer<UInt8>,
		length bytesToRead: Int,
	) throws -> Int {
		var bytesRead: Int = 0
		
		repeat {
			bytesRead = Libc.read(
				fd,
				buffer,
				bytesToRead,
			)
		} while bytesRead < 0 && errno == EINTR
		
		try POSIX.checkError(
			bytesRead >= 0,
		)
		
		return bytesRead
	}
	
	public static func write(
		fd: Int32,
		buffer : UnsafeMutablePointer<UInt8>,
		length bytesToWrite: Int,
	) throws {
		var bytesWritten: Int = 0
		
		while bytesWritten < bytesToWrite {
			var written: Int = 0
			let bytesLeftToWrite = bytesToWrite - bytesWritten
			
			repeat {
				written = Libc.write(
					fd,
					buffer.advanced(by: bytesWritten),
					bytesLeftToWrite,
				)
			} while written < 0 && errno == EINTR
			
			try POSIX.checkError(
				written >= 0,
			)
			
			bytesWritten += written
		}
	}
	
}


// MARK: - Symlink Operation


extension POSIX {

	public static func createLink(
		at path: String,
		of target: String,
	) throws {
		try POSIX.checkError(
			link(target, path) == 0
		)
	}
	
	public static func readlink(
		at path: String,
	) throws -> String {
		try String(capacity: PATH_MAX) { buffer in
			let result = Libc.readlink(
				path,
				buffer.baseAddress!,
				buffer.count
			)
			
			try POSIX.checkError(
				result >= 0
			)
			
			return result
		}
	}
	
	public static func createSymlink(
		at path: String,
		of target: String,
	) throws {
		try POSIX.checkError(
			symlink(target, path) == 0
		)
	}
	
	public static func copySymlink(
		at source: String,
		to destination: String,
	) throws {
		let link: String
		= try readlink(at: source)
		
		try POSIX.checkError(
			symlink(link, destination) == -0
		)
	}
	
}


// MARK: - Directory Operation


extension POSIX {

	public static func createDirectory(
		at path: String,
	) throws {
		let defaultMode: mode_t
		= FilePermissions(owner: .all, group: .all, other: .readExecute).mode
		
		for path in FilePath(path).ancestors {
			mkdir(path.asString, defaultMode)
		}
		
		guard
			mkdir(path, defaultMode) == 0
		else {
			switch errno {
				case EEXIST:
					// OK
					return
					
				default:
					throw POSIXError.system
			}
		}
	}
	
	public static func deleteDirectory(
		at path: String,
		recursive: Bool = false,
		force: Bool = false,
	) throws {
		if recursive == true {
			for entry in try scandir(at: path, depth: 1) {
				let subpath = FilePath.join(path, entry.relativePath)
				
				switch entry.type {
					case .file, .link:
						try unlink(at: subpath)
						
					case .directory:
						if recursive {
							try deleteDirectory(
								at: subpath,
								recursive: true,
								force: force
							)
						} else {
							try POSIX.checkError(
								rmdir(path.asString) == 0
							)
						}
						
					default:
						if force {
							try? unlink(at: subpath)
						}
				}
			}
		}
		
		try POSIX.checkError(
			rmdir(path.asString) == 0
		)
	}
	
	public static func copyDirectory(
		at source: String,
		to destination: String,
	) throws {
		try createDirectory(
			at: destination,
		)
		
		for (path, type) in try scandir(at: source, depth: 1) {
			switch type {
				case .file:
					try copyFile(
						at: FilePath.join(source, path),
						to: FilePath.join(destination, path),
					)
					
				case .link:
					try copySymlink(
						at: FilePath.join(source, path),
						to: FilePath.join(destination, path),
					)

				case .directory:
					try copyDirectory(
						at: FilePath.join(source, path),
						to: FilePath.join(destination, path),
					)
					
				default:
					break
			}
		}
	}
	
}


