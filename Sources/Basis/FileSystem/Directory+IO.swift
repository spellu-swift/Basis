import Libc


extension Directory {
		
	public func createFile(
		data: Binary,
		atomic: Bool = false,
	) throws {
		try self.path.file.save(
			data,
			atomic: atomic,
		)
	}
	
	public func createDirectory(
		_ subpath: String? = nil,
	) throws {
		try POSIX.createDirectory(
			at: path[subpath].expanded,
		)
	}
	
	public func deleteDirectory(
		_ subpath: String? = nil,
		recursive: Bool = false,
	) throws {
		try POSIX.deleteDirectory(
			at: path[subpath].expanded,
			recursive: recursive,
		)
	}

	public func createLink(
		_ subpath: String? = nil,
		of target: FilePath,
	) throws {
		try POSIX.createLink(
			at: path[subpath].expanded,
			of: target.expanded,
		)
	}

	public func createSymlink(
		_ subpath: String? = nil,
		of target: FilePath,
	) throws {
		try POSIX.createSymlink(
			at: path[subpath].expanded,
			of: target.expanded,
		)
	}

	/// ディレクトリをコピーする。省略時は深さを制限せずコピーする。
	public func copy(
		_ subpath: String? = nil,
		to: FilePath,
		recursive: Recursive = .unlimited,
	) throws {
		try? to.directory.deleteDirectory()
		
		try to.directory.createDirectory()
		
		for entry in try path[subpath].directory.list(
			followLinks: false,
			recursive: recursive,
		) {
			switch entry.type {
				case .file:
					try entry.fullPath.file.copy(
						to: to.appending(entry.relativePath),
					)
					
				case .link:
					try POSIX.copySymlink(
						at: entry.fullPath.expanded,
						to: to.appending(entry.relativePath).expanded,
					)

				case .directory:
					try to.directory[entry.relativePath].createDirectory()
					
				default:
					break
			}
		}
	}
	
}
