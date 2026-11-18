import Libc


public struct FilePath : Sendable {

	@inlinable
	public init(
		_ path: String,
	) {
		self._path
		= FilePathComponents
			.parse(path, directoryOnly: false)
			.build()
	}
	
	@inlinable
	public init(
		_ path: Substring,
	) {
		self._path
		= FilePathComponents
			.parse(path, directoryOnly: false)
			.build()
	}
	
	@inlinable
	public init(
		noCheck path: String,
	) {
		self._path = path
	}
	
	@inlinable
	public init(
		_ components: String?...,
	) {
		self.init(
			FilePath.join(components.compacted()),
		)
	}
	
	@inlinable
	public init(
		_ components: [String],
	) {
		self.init(
			FilePath.join(components),
		)
	}

	@usableFromInline
	package let _path: String
	
	
	@inlinable
	public var asString: String {
		_path
	}
	

	@inlinable
	public var isAbsolute: Bool {
		_path.first == "/"
	}
	

	@inlinable
	public var isRelative: Bool {
		!isAbsolute
	}

	/// カレントディレクトリ基準で絶対化する。存在確認・リンク解決は行わない。
	@inlinable
	public var absoluted: FilePath {
		absoluted(relativeTo: Backbone.workingDirectory, as: .directory)
	}

	/// 絶対パスの基準を種別とともに指定する。
	@inlinable
	public func absoluted(
		relativeTo base: String,
		as kind: Kind? = nil,
	) -> FilePath {
		absoluted(relativeTo: FilePath(base), as: kind)
	}

	@inlinable
	public func absoluted(
		relativeTo base: FilePath,
		as kind: Kind? = nil,
	) -> FilePath {
		precondition(base.isAbsolute)
		return resolved(relativeTo: base, as: kind)
	}

	/// 相対パスを作成する
	@inlinable
	public func relatived(
		base: FilePath,
	) -> FilePath {
		.init(_path.trimmingPrefix(base.expanded + "/"))
	}
	
	/// パスを正規化する
	@inlinable
	public var normalized: FilePath {
		.init(
			noCheck: FilePath.normalizePath(_path)
		)
	}

	/// パスがリンクを指している場合、解決したパスを返す。それ以外の場合はパス。
	@inlinable
	public var realized: FilePath {
		realpath ?? self
	}

	/// パスがリンクを指している場合のその実体、またはnil
	public var realpath: FilePath? {
		do {
			let path: String = try POSIX.realpath(_path)
			
			if FileStatus(at: path, followLink: false)?.type == .directory {
				return FilePath(path + "/")
			}
			else {
				return FilePath(path)
			}
		}
		catch {
			// No such file or directory.
			return nil
		}
	}
	

	@inlinable
	public var expanded: String {
		FilePath.expand(_path)
	}
		
	@inlinable
	public func expanded(
		values: [String : String],
	) -> String {
		FilePath.expand(_path, values: values)
	}
	
}


extension FilePath : ExpressibleByStringLiteral {
	
	@inlinable
	public init(
		stringLiteral value: StringLiteralType,
	) {
		self.init(value)
	}
	
}


extension FilePath : CustomStringConvertible {
	
	@inlinable
	public var description: String {
		_path
	}

}


extension FilePath : Equatable {
		
	@inlinable
	public static func ==(
		_ lhs: Self,
		_ rhs: Self,
	) -> Bool {
		lhs._path == rhs._path
	}

}


extension FilePath : Hashable {}


// MARK: - Path Components


extension FilePath {
	
	public enum ExtensionSeparatePosition {
		case first
		case last(Int)
		
		public static var last: Self {
			.last(1)
		}
	}
	
	@inlinable
	public var basePath: FilePath {
		.init(FilePath.splitPath(_path).0)
	}
	
	@inlinable
	public var baseName: String {
		FilePath.splitPath(_path).0
	}
	
	@inlinable
	public var fileName: String {
		FilePath.splitPath(_path).1?.asString ?? ""
	}
	
	@inlinable
	public var fileNameWithoutExtension: String {
		if
			let ext: String = self.extension
		{
			return fileName.dropLast(1 + ext.count).asString
		}
		else {
			return fileName
		}
	}
	
	@inlinable
	public func fileNameWithoutExtension(
		position: ExtensionSeparatePosition,
	) -> String {
		if
			let ext: String = self.extension(
				position: position
			)
		{
			return fileName.dropLast(1 + ext.count).asString
		}
		else {
			return fileName
		}
	}
	
	@inlinable
	public func fileNameWithoutExtension(
		_ ext: String,
	) -> String {
		if
			self.hasExtension(ext)
		{
			return fileName.dropLast(1 + ext.count).asString
		}
		else {
			return fileName
		}
	}
	
	@inlinable
	public var `extension`: String? {
		`extension`(position: .last)
	}
	
	public func `extension`(
		position: ExtensionSeparatePosition,
	) -> String? {
		guard
			let name: Substring = FilePath.splitPath(_path).1
		else { return nil }
		
		switch position {
			case .first:
				return name
					.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
					.get(at: 1)?
					.asString
				
			case .last(let count):
				let parts: ArraySlice<Substring> = name
					.split(separator: ".", maxSplits: Int.max, omittingEmptySubsequences: true)
					.dropFirst()
				
				guard parts.count > 0
				else { return nil }

				return parts
					.last(min(count, parts.count))
					.joined(separator: ".")
		}
	}
	
	public var dottedExtension: String {
		if
			let ext = `extension`
		{
			return ".\(ext)"
		} else {
			return ""
		}
	}
	
	public func dottedExtension(
		position: ExtensionSeparatePosition,
	) -> String {
		if
			let ext = `extension`(position: position)
		{
			return ".\(ext)"
		} else {
			return ""
		}
	}
	
	@inlinable
	public func hasExtension<String>(
		_ extension: String,
	) -> Bool where String : StringProtocol {
		_path.hasSuffix(`extension`)
	}
	
	public var parent: FilePath {
		var path: FilePathComponents = .parse(_path)
		
		if path.components.count > 0 {
			path.components.removeLast()
		}
		
		return .init(
			path.build()
		)
	}
	
	public var ancestors: [FilePath] {
		let absolute: Bool = _path.hasPrefix("/")
		let parts: [Substring] = _path.split(separator: "/")
		
		return (1..<parts.count)
			.map { n in
				(absolute ? "/" : "") + parts[0..<n].joined(separator: "/")
			}
			.map {
				FilePath($0)
			}
	}
	
}


// MARK: - Path Operation


extension FilePath {
	
	@inlinable
	public func appending(
		_ parts: String?...,
	) -> FilePath {
		.init(
			FilePath.join(_path, parts.compacted())
		)
	}
	
	@inlinable
	public func appending(
		_ parts: [String],
	) -> FilePath {
		.init(
			FilePath.join(_path, parts)
		)
	}

	@inlinable
	public func appending(
		`extension`: String,
	) -> FilePath {
		.init(
			"\(_path).\(`extension`)"
		)
	}

	@inlinable
	public func replacing(
		fileName: String,
	) -> FilePath {
		self.parent.appending(fileName)
	}
	
	@inlinable
	public func replacing(
		`extension`: String,
		position: ExtensionSeparatePosition = .last,
	) -> FilePath {
		if
			let oldExtension: String = self.extension(position: position)
		{
			return .init(
				_path.dropLast(oldExtension.count) + `extension`
			)
		}
		else {
			return .init(
				"\(_path).\(`extension`)"
			)
		}
	}
	
}


// MARK: - Path resolving


extension FilePath {

	public enum Kind : Sendable {
		case file
		case directory
	}

	@inlinable
	public init(
		relativeTo base: String,
		as kind: Kind? = nil,
		_ path: String,
	) {
		self = FilePath(path).resolved(relativeTo: base, as: kind)
	}

	@inlinable
	public init(
		relativeTo base: FilePath,
		as kind: Kind? = nil,
		_ path: String,
	) {
		self = FilePath(path).resolved(relativeTo: base, as: kind)
	}

	/// ..はリンクを含むパスの意味を変えないよう保持する。
	/// 字句的な正規化はnormalized、実体の解決はrealpathで明示する。
	@inlinable
	public func resolved(
		relativeTo base: String,
		as kind: Kind? = nil,
	) -> FilePath {
		.init(noCheck: FilePath.resolvePath(
			relativeTo: base,
			as: kind,
			path: _path,
		))
	}

	@inlinable
	public func resolved(
		relativeTo base: FilePath,
		as kind: Kind? = nil,
	) -> FilePath {
		resolved(relativeTo: base.asString, as: kind)
	}
}


// MARK: - [] (subscript)


extension FilePath {
	
	/// 相対パスなら後ろに結合し、絶対パスならそのまま返す。
	@inlinable
	public subscript(
		path: FilePath,
	) -> FilePath {
		if path.isAbsolute {
			path
		} else {
			appending(path._path)
		}
	}
	
	@inlinable
	public subscript(
		path components: String?...,
	) -> FilePath {
		appending(components.compacted())
	}
	
	@inlinable
	public subscript(
		path components: [String],
	) -> FilePath {
		appending(components)
	}
	
	@inlinable
	public subscript(
		status components: String?...,
	) -> FileStatus? {
		self[path: components.compacted()].status
	}
	
	@inlinable
	public subscript(
		status components: [String],
	) -> FileStatus? {
		self[path: components].status
	}
	
	@inlinable
	public subscript(
		file components: String?...,
	) -> File {
		File(
			at: self[path: components.compacted()]
		)
	}

	@inlinable
	public subscript(
		file components: [String],
	) -> File {
		File(
			at: self[path: components]
		)
	}
	
	@inlinable
	public subscript(
		directory components: String?...,
	) -> Directory {
		Directory(
			at: self[path: components.compacted()]
		)
	}
	
	@inlinable
	public subscript(
		directory components: [String],
	) -> Directory {
		Directory(
			at: self[path: components]
		)
	}
	
	@inlinable
	public subscript(
		_ components: String?...,
	) -> Self {
		self[path: components.compacted()]
	}
	
	@inlinable
	public subscript(
		_ components: [String],
	) -> Self {
		self[path: components]
	}

}


// MARK: -


extension FilePath {

	@inlinable
	public static func join(
		_ components: String?...,
	) -> String {
		join(components.compacted())
	}
	
	@inlinable
	public static func join(
		_ path: String,
		_ components: [String],
	) -> String {
		join([path] + components)
	}
	
	public static func join(
		_ components: [String],
	) -> String {
		let components: [String]
		= components.filter{$0 != ""}
		
		guard components.count > 0
		else { return "" }
		
		let absolute: Bool = components[0].first == "/"
		
		return (absolute ? "/" : "")
		+ components
			.map{ $0.trimming(#/\/+/#) }
			.joined(separator: "/")
	}
	
}


extension FilePath {

	/// ファイルパスの構成要素をオブジェクトで返す。
	@inlinable
	public var components: FilePathComponents {
		FilePathComponents.parse(_path)
	}

	/// ファイルパスの構成名を配列で返す。
	@inlinable
	public var names: [String] {
		components.names
	}
	
	
	/// ファイルパスを分割する。
	public func divide(
		first count: Int
	) -> (FilePath, [String]) {
		let pair = components.divide(first: count)
		
		return (pair.0.asFilePath, pair.1)
	}
	
	
	/// ファイル名にPrefixまたはSuffixを挿入する。
	public func insert(
		prefix: String? = nil,
		suffix: String? = nil
//		position: ExtensionSeparatePosition = .last
	) -> FilePath {
		let parent = self.parent
		
		var fileName = ""
		
		if let prefix = prefix {
			fileName += prefix
		}
		
		fileName += self.fileNameWithoutExtension
		
		if let suffix = suffix {
			fileName += suffix
		}
		
		if let ext = self.extension {
			fileName += "." + ext
		}
		
		return parent.appending(fileName)
	}
	
	
}
