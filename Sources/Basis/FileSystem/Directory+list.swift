

extension Directory {
	
	/// ディレクトリエントリ
	public struct Entry {
		public init(
			basePath: FilePath,
			relativePath: String,
			type: FileType,
		) {
			self.basePath = basePath
			self.relativePath = relativePath
			self.type = type
		}
		
		public let basePath: FilePath
		
		public let relativePath: String
		
		public var fullPath: FilePath {
			basePath[relativePath]
		}
		
		public let type: FileType
	}

	/// ディレクトリ内のエントリを列挙する。
	///
	/// parameter:
	///   - recursive: ex) false, true, .depth(5), .unlimited
	///   - filter:
	///     - return: true  == POSIX.DirectoryEnumerateContext.include
	///               false == POSIX.DirectoryEnumerateContext.exclude
	public func list(
		followLinks: Bool = false,
		recursive: Recursive = false,
		filter: @escaping (POSIX.DirectoryEnumerateContext) -> POSIX.DirectoryEnumerateAction,
	) throws -> [Directory.Entry] {
		try POSIX.scandir(
			at: path.expanded,
			followLinks: followLinks,
			depth: recursive.depth,
			filter: filter,
		)
		.map {
			Directory.Entry(
				basePath: path,
				relativePath: $0,
				type: $1,
			)
		}
	}
	
	/// ディレクトリ内のエントリを列挙する。
	///
	/// parameter:
	///   - recursive: ex) false, true, .depth(5), .unlimited
	///   - filter:
	///     - return: true  == POSIX.DirectoryEnumerateContext.include
	///               false == POSIX.DirectoryEnumerateContext.exclude
	public func list(
		followLinks: Bool = false,
		recursive: Recursive = false,
		filter: @escaping (POSIX.DirectoryEnumerateContext) -> Bool = { _ in true },
	) throws -> [Directory.Entry] {
		try POSIX.scandir(
			at: path.expanded,
			followLinks: followLinks,
			depth: recursive.depth,
			filter: {
				filter($0) ? .include : .exclude
			},
		)
		.map {
			Directory.Entry(
				basePath: path,
				relativePath: $0,
				type: $1,
			)
		}
	}
	
}


extension Directory {
		
	public struct Recursive {
		var depth: Int
	}
	
}


extension Directory.Recursive : ExpressibleByBooleanLiteral {
	
	public init(
		booleanLiteral value: Bool,
	) {
		if value {
			self.depth = 5
		} else {
			self.depth = 1
		}
	}
	
	public static func depth(
		_ depth: Int,
	) -> Self {
		.init(depth: depth)
	}
	
	public static var unlimited: Self {
		.init(depth: .max)
	}
		
}
