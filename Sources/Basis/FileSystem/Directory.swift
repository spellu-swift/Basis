

public struct Directory : Sendable {
	
	@inlinable
	public init(
		at components: String?...,
	) {
		self.path = .init(components.compacted())
	}
	
	@inlinable
	public init(
		at components: [String],
	) {
		self.path = .init(components)
	}
	
	@inlinable
	public init(
		at path: FilePath,
	) {
		self.path = path
	}

	public let path: FilePath
	
	
	@inlinable
	public var absoluted: Directory {
		.init(at: path.absoluted)
	}
	
	@inlinable
	public func absoluted(
		relativeTo base: String,
		as kind: FilePath.Kind? = nil,
	) -> Directory {
		.init(at: path.absoluted(relativeTo: base, as: kind))
	}

	@inlinable
	public func absoluted(
		relativeTo base: FilePath,
		as kind: FilePath.Kind? = nil,
	) -> Directory {
		.init(at: path.absoluted(relativeTo: base, as: kind))
	}

	@inlinable
	public var parent: Directory {
		.init(
			at: path.parent
		)
	}
	
}



extension Directory {
		
	@inlinable
	public subscript(
		path components: String?...,
	) -> FilePath {
		path.appending(components.compacted())
	}
	
	@inlinable
	public subscript(
		path components: [String]
	) -> FilePath {
		path.appending(components)
	}
	
	@inlinable
	public subscript(
		status components: String?...,
	) -> FileStatus? {
		path.appending(components.compacted()).status
	}

	@inlinable
	public subscript(
		status components: [String],
	) -> FileStatus? {
		path.appending(components).status
	}
	
	@inlinable
	public subscript(
		file components: String?...,
	) -> File {
		File(
			at: path.appending(components.compacted()),
		)
	}
	
	@inlinable
	public subscript(
		file components: [String],
	) -> File {
		File(
			at: path.appending(components),
		)
	}
	
	@inlinable
	public subscript(
		directory components: String?...,
	) -> Directory {
		Directory(
			at: path.appending(components.compacted()),
		)
	}

	@inlinable
	public subscript(
		directory components: [String],
	) -> Directory {
		Directory(
			at: path.appending(components),
		)
	}
	
	@inlinable
	public subscript(
		_ components: String?...,
	) -> Self {
		Directory(
			at: path.appending(components.compacted()),
		)
	}
	
	@inlinable
	public subscript(
		_ components: [String],
	) -> Self {
		Directory(
			at: path.appending(components),
		)
	}
	
}
