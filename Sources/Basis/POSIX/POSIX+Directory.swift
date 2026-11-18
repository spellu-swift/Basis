import Libc


extension POSIX {

	public static func scandir(
		at path: String,
		followLinks: Bool = false,
		depth: Int = 1,
		filter: @escaping (DirectoryEnumerateContext) -> DirectoryEnumerateAction,
	) throws -> [(relativePath: String, type: FileType)] {
		try _scandir(
			directory: path,
			level: 1,
			prefix: "",
			followLinks: followLinks,
			depth: depth,
			filter: filter,
		)
	}

	public static func scandir(
		at path: String,
		followLinks: Bool = false,
		depth: Int = 1,
		filter: @escaping (DirectoryEnumerateContext) -> Bool = { _ in true },
	) throws -> [(relativePath: String, type: FileType)] {
		try _scandir(
			directory: path,
			level: 1,
			prefix: "",
			followLinks: followLinks,
			depth: depth,
			filter: { filter($0) ? .include : .exclude }
		)
	}

	public struct DirectoryEnumerateContext {
		public init(
			basePath: FilePath,
			relativePath: String,
			level: Int,
			name: String,
			type: FileType?,
		) {
			self.basePath = basePath
			self.relativePath = relativePath
			self.level = level
			self.name = name
			self.type = type
		}

		public let basePath: FilePath

		public let relativePath: String

		public var absolutePath: FilePath {
			basePath[relativePath]
		}

		public let level: Int

		public let name: String

		public let type: FileType?
	}

	public enum DirectoryEnumerateAction /*: ExpressibleByBooleanLiteral*/ {
		case include
		case exclude
		case ignore

		//		public init(
		//			booleanLiteral value: BooleanLiteralType
		//		) {
		//			self = value ? .include : .exclude
		//		}
	}

	static func _scandir(
		directory: String,
		level: Int,
		prefix: String,
		followLinks: Bool,
		depth: Int,
		filter: @escaping (DirectoryEnumerateContext) -> DirectoryEnumerateAction,
	) throws -> [(String, FileType)] {
		guard
			level <= depth
		else { return [] }

		var result: [(String, FileType)] = []

		try enumerateDirectoryEntries(path: directory) { name, type in
			let relativePath: String = prefix.appendingPath([name])

			var type: FileType? = type

			if type == .link && followLinks {
				do {
					let targetPath: String
					= try POSIX.realpath(FilePath.join(directory, name).asString)

					type = FileStatus(at: targetPath, followLink: true)?.type
				}
				catch {
					// リンク先が存在しない
					type = .none
				}
			}

			//- フィルタ

			let action: DirectoryEnumerateAction = filter(
				DirectoryEnumerateContext(
					basePath: FilePath(directory),
					relativePath: relativePath,
					level: level,
					name: name,
					type: type,
				)
			)

			//- 追加
			if
				let type,
				action == .include
			{
				result.append((relativePath, type))
			}

			//- 再帰検索

			if type == .directory,
				action != .exclude
			{
				result += try _scandir(
					directory: FilePath.join(directory, name),
					level: level + 1,
					prefix: relativePath,
					followLinks: followLinks,
					depth: depth,
					filter: filter,
				)
			}
		}

		return result
	}

	public static func enumerateDirectoryEntries(
		path: String,
		perform: @escaping (String, FileType) throws -> Void,
	) throws {
		let dir = try POSIX.checkError(
			opendir(path),
		)

		defer { closedir(dir) }

		while true {
			errno = 0
			guard let pointer = readdir(dir) else {
				guard errno == 0 else { throw POSIXError.system }
				break
			}
			let entry: dirent = pointer.pointee
			let DOT: CChar = 46  // "."

			// ".", ".." を無視する
			if entry.d_name.0 == DOT {
				if entry.d_name.1 == 0 { continue }
				if entry.d_name.1 == DOT && entry.d_name.2 == 0 { continue }
			}

			let name: String = withUnsafePointer(to: entry.d_name) {
				String(
					cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
				)
			}

			let type: FileType = dTypeAsFileType(entry.d_type)

			try perform(name, type)
		}
	}

	static func dTypeAsFileType(
		_ d_type: UInt8,
	) -> FileType {
		#if canImport(Darwin)
			let type: Int32 = .init(d_type)
		#elseif canImport(Musl)
			let type: Int32 = .init(d_type)
		#else
			let type: Int = .init(d_type)
		#endif
		switch type {
		case DT_FIFO:  // 0x1
			return .file
		case DT_CHR:  // 0x2
			return .character
		case DT_DIR:  // 0x4
			return .directory
		case DT_BLK:  // 0x6
			return .block
		case DT_REG:  // 0x8
			return .file
		case DT_LNK:  // 0xA
			return .link
		case DT_SOCK:  // 0xC
			return .socket
		//			case DT_WHT:  // 0xE
		//				return .wht
		default:
			return .unknown
		}
	}

}


extension String {

	fileprivate func appendingPath(
		_ parts: [String?],
	) -> String {
		let parts: [String] = parts.compacted()

		if parts.count == 0 {
			return self
		}
		else if self == "" {
			return parts.joined(separator: "/")
		}
		else {
			return
				self.trimmingSuffix(#/\/+/#)
				+ parts.map { "/" + $0 }.joined()
		}
	}

}
