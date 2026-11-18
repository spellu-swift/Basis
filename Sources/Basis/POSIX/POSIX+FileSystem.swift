import Libc


extension POSIX {
	
	
	public static func getcwd(
	) -> String {
		withUnsafeTemporaryAllocation(of: CChar.self, capacity: PATH_MAX) { buffer in
			_ = Libc.getcwd(buffer.baseAddress!, buffer.count)
			
			return String(cString: buffer.baseAddress!)
		}
	}
	
	
	public static func chdir(
		_ path: String
	) throws {
		try POSIX.checkError(
			Libc.chdir(path)
		) { $0 == 0 }
	}
	
	
	/// 実行中のプロセスが、パスに指定した操作をできるか調べる。
	///
	/// 権限のビットだけでなく、所有者・グループ・ACL・読み取り専用のマウントもOSが判定する。
	/// シンボリックリンクの場合はリンク先を調べる。
	///
	/// - Parameter access: 調べる操作。空なら存在するかだけを調べる。
	/// - Returns: パスが存在しない場合はfalse
	public static func access(
		_ path: String,
		_ access: FilePermissions.Access,
	) -> Bool {
		var mode: Int32 = 0

		if access.contains(.read) { mode |= R_OK }
		if access.contains(.write) { mode |= W_OK }
		if access.contains(.execute) { mode |= X_OK }

		return Libc.access(path, access.isEmpty ? F_OK : mode) == 0
	}
	
	
	/// 権限を変更する。シンボリックリンクの場合はリンク先を変更する。
	public static func chmod(
		_ path: String,
		_ permissions: FilePermissions,
	) throws {
		try POSIX.checkError(
			Libc.chmod(path, permissions.mode)
		) { $0 == 0 }
	}
	
	
	public static func utimes(
		_ path: String,
		accessTime: ClockTime? = nil,
		modificationTime: ClockTime? = nil
	) throws {
		guard
			let status: FileStatus = .init(at: path, followLink: false)
		else { throw POSIXError.system }
		
		let accessTime: ClockTime = accessTime ?? status.accessTime
		let modificationTime: ClockTime = modificationTime ?? status.modificationTime
		
		let array: [timeval]
		= [
			timeval(
				tv_sec: Int(accessTime.seconds),
				tv_usec: numericCast(accessTime.micro),
			),
			timeval(
				tv_sec: Int(modificationTime.seconds),
				tv_usec: numericCast(modificationTime.micro),
			),
		]
		
		try array.withUnsafeBufferPointer {
			try POSIX.checkError(
				Libc.utimes(path, $0.baseAddress)
			) { $0 == 0 }
		}
	}
	
	
	public static func realpath(
		_ path: String
	) throws -> String {
		try String(capacity: PATH_MAX) { buffer in
			let result: UnsafeMutablePointer<CChar> = try POSIX.checkError(
				Libc.realpath(
					path,
					buffer.baseAddress
				)
			)
			
			return strlen(result)
		}
	}


	public static func gethostname(
	) throws -> String {
		let nameMaxSize: Int = 256 // HOST_NAME_MAX

		return try POSIX.checkError(
			withUnsafeTemporaryAllocation(of: CChar.self, capacity: nameMaxSize) { buffer in
				_ = Libc.gethostname(buffer.baseAddress!, buffer.count)
			
				return String(cString: buffer.baseAddress!)
			}
		)
	}
	
	
}
