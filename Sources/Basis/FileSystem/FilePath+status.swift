import Libc


extension FilePath {
	
	@inlinable
	public var status: FileStatus? {
		.init(at: expanded, followLink: true)
	}
	
	/// 実行中のプロセスが、パスに指定した操作をできるか調べる。``POSIX/access(_:_:)``と同じ。
	@inlinable
	public func access(
		_ access: FilePermissions.Access,
	) -> Bool {
		POSIX.access(expanded, access)
	}

	@inlinable
	public var fileExisting: File? {
		status?.type == .file
			? File(at: self)
			: nil
	}

	@inlinable
	public var directoryExisting: Directory? {
		status?.type == .directory
			? Directory(at: self)
			: nil
	}	
	
}

