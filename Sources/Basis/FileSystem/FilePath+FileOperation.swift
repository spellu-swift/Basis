import Libc


// MARK: - File Operation


extension FilePath {
	
	public func move(
		to destination: FilePath,
	) throws {
		try POSIX.move(
			at: self.expanded,
			to: destination.expanded,
		)
	}
	
	public func copy(
		to destination: FilePath,
	) throws {
		try POSIX.copy(
			at: self.expanded,
			to: destination.expanded,
		)
	}
	
	public func delete(
	) throws {
		try POSIX.delete(
			at: self.expanded,
		)
	}
	
	/// 権限を変更する。シンボリックリンクの場合はリンク先を変更する。
	public func setPermissions(
		_ permissions: FilePermissions,
	) throws {
		try POSIX.chmod(
			self.expanded,
			permissions,
		)
	}
	
	/// 今の権限をもとに、一部だけ変更する。
	///
	/// ```swift
	/// try path.updatePermissions { $0.insert(.ownerExecute) }
	/// ```
	public func updatePermissions(
		_ body: (inout FilePermissions) throws -> Void,
	) throws {
		guard
			var permissions: FilePermissions = status?.permissions
		else { throw POSIXError.system(ENOENT) }
		
		try body(&permissions)
		
		try setPermissions(permissions)
	}
	
}
