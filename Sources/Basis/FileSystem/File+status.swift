import Libc


extension File {
	
	@inlinable
	public var status: FileStatus? {
		path.status
	}
	
	@inlinable
	public var exists: Bool {
		status?.type == .file
	}
	
	@inlinable
	public var permissions: FilePermissions? {
		status?.permissions
	}
	
	@inlinable
	public func setPermissions(
		_ permissions: FilePermissions,
	) throws {
		try path.setPermissions(permissions)
	}
	
	@inlinable
	public var size: Int64? {
		status?.size
	}
	
	@inlinable
	public var accessTime: ClockTime? {
		status?.accessTime
	}
	
	@inlinable
	public var modificationTime: ClockTime? {
		status?.modificationTime
	}
	
#if canImport(Darwin)
	@inlinable
	public var creationTime: ClockTime? {
		status?.creationTime
	}
#endif
	
	@inlinable
	public func set(
		accessTime: ClockTime? = nil,
		modificationTime: ClockTime? = nil
	) throws {
		try POSIX.utimes(
			path.asString,
			accessTime: accessTime,
			modificationTime: modificationTime
		)
	}
	
	/// 実行中のプロセスが、指定した操作をできるか調べる。``POSIX/access(_:_:)``と同じ。
	@inlinable
	public func access(
		_ access: FilePermissions.Access,
	) -> Bool {
		path.access(access)
	}
	
	/// 実行中のプロセスが読み取れるか。存在しなければfalse
	@inlinable
	public var isReadable: Bool {
		access(.read)
	}
	
	/// 実行中のプロセスが書き込めるか。存在しなければfalse
	@inlinable
	public var isWritable: Bool {
		access(.write)
	}
	
	/// 実行中のプロセスが実行できるか。ディレクトリの場合は中に入れるか。存在しなければfalse
	@inlinable
	public var isExecutable: Bool {
		access(.execute)
	}
	
	@inlinable
	public var readonly: Bool {
		isReadable && !isWritable
	}
	
	@inlinable
	public var link: String? {
		try? POSIX.readlink(at: path.expanded)
	}
	
	@inlinable
	public var linkTarget: FilePath? {
		guard let link
		else { return nil }

		return FilePath(link).resolved(relativeTo: path, as: .file).realpath
	}
	
}
