

extension FilePathComponents {
	
	
	@inlinable
	public static func parse(
		_ path: String,
		directoryOnly: Bool = false
	) -> Self {
		parse(
			path[...],
			directoryOnly: directoryOnly
		)
	}


	public static func parse(
		_ path: Substring,
		directoryOnly: Bool = false
	) -> Self {
		let components: [Substring] = path.split(
			separator: "/",
			omittingEmptySubsequences: true // 連続した"/"を除去する指定
		)
		let componentCount: Int = components.count
		
		return Self(
			absolute: path.hasPrefix("/"),
			components: (0..<componentCount)
				.map { index in
					if index == componentCount - 1 {
						return (components[index], path.hasSuffix("/"))
					}
					else {
						return (components[index], true)
					}
				}
				.filter {
					directoryOnly ? $0.1 == true : true
				}
		)
	}
	
	
	public static func combine(
		_ left: FilePathComponents,
		_ right: FilePathComponents
	) -> Self {
		return Self(
			absolute: left.absolute,
			components: left.components + right.components
		)
	}
	
	
}


///
/// UNIXパス形式を解析する
///
public struct FilePathComponents {
	
	
	public init(
		absolute: Bool,
		components: [(Substring, Bool)]
	) {
		self.absolute = absolute
		self.components = components
	}
	

	public var absolute: Bool
	public var components: [(Substring, Bool)]
	
	
	public var names: [String] {
		components.map{ $0.0.asString }
	}


	public func divide(
		first count: Int
	) -> (FilePathComponents, [String]) {
		let pair = components.divide(first: count)
		
		return (
			FilePathComponents(
				absolute: absolute,
				components: pair.0
			),
			pair.1.map{$0.0.asString}
		)
	}


	public func build(
	) -> String {
		let path: String = components
			.map{ $0 + ($1 ? "/" : "") }
			.joined(separator: "")
		
		return absolute ? "/" + path : path
	}
	
	
	public var asFilePath: FilePath {
		FilePath(build())
	}
	
	
}
