

extension FilePath {

	/// POSIXのシェルのチルダ展開と変数展開（XCU 2.6.1・2.6.2）に従って、文字列を展開する。
	///
	/// - 先頭の`~`はHOMEの値に、`~user`はそのユーザーのホームディレクトリに置き換える。
	///   HOMEがない場合や、知らないユーザーの場合はそのまま残す。
	/// - `${name}`を変数の値に置き換える。名前は大文字・小文字を区別し、未定義なら空にする。
	/// - 置き換えた値の中の`~`や`$`は、再び展開しない。
	///
	/// - Parameter values: 変数の値。省略すると環境変数を使う。
	public static func expand(
		_ string: String,
		values: [String : String]? = nil
	) -> String {
		let values: [String : String]
		= values ?? Backbone.environment.values

		guard string.hasPrefix("~")
		else { return expandVariables(string[...], values: values) }

		// チルダの部分は、最初の/の直前まで
		let end: String.Index = string.firstIndex(of: "/") ?? string.endIndex
		let name: Substring = string[string.index(after: string.startIndex) ..< end]
		let rest: Substring = string[end...]

		let home: String?
		= name.isEmpty
			? values["HOME"]
			: Backbone.user(String(name))?.user.pw_dir.asString

		guard var home
		else { return string[..<end] + expandVariables(rest, values: values) }

		// 続く/と重ならないように、ホームの末尾の/を省く
		if rest.hasPrefix("/") && home.hasSuffix("/") {
			home.removeLast()
		}

		return home + expandVariables(rest, values: values)
	}

	private static func expandVariables(
		_ string: Substring,
		values: [String : String],
	) -> String {
		String(
			string.replacing(
				/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/
			) { match in
				values[String(match.1)] ?? ""
			}
		)
	}

	/// 文字列の配列を展開する。
	public static func expand(
		_ strings: [String],
		values: [String : String]? = nil
	) -> [String] {
		strings.map {
			expand($0, values: values)
		}
	}

	/// パスを展開する。
	public static func expand(
		_ path: FilePath,
		values: [String : String]? = nil
	) -> FilePath {
		.init(
			expand(path.asString, values: values)
		)
	}
	
	/// パスの配列を展開する。
	public static func expand(
		_ paths: [FilePath],
		values: [String : String]? = nil
	) -> [FilePath] {
		paths.map {
			expand($0, values: values)
		}
	}

}


extension FilePath {

	/// kindがnilの場合だけ、末尾の/があればディレクトリと判断する。
	/// 存在確認とリンク解決、..の除去は行わない。
	public static func resolvePath(
		relativeTo base: String,
		as kind: FilePath.Kind? = nil,
		path: String,
	) -> String {
		let target: FilePathComponents = .parse(path)
		if target.absolute { return target.build() }
		let directory: String
		switch kind ?? (base.hasSuffix("/") ? .directory : .file) {
			case .directory: directory = base
			case .file: directory = FilePath(base).parent.asString
		}
		if path.isEmpty || path == "." { return directory }
		var result: FilePathComponents = .parse(
			FilePath.join(directory, [path])
		)
		result.components.removeAll { $0.0 == "." }
		return result.build()
	}

	/// baseからの相対パスとして解決する。
	public static func normalizePath(
		_ path: String
	) -> String {
		//- パスを正規化する

		return normalizePath(
			.parse(path)
		)
	}
	
	/// baseからの相対パスとして解決する。
	public static func normalizePath(
		_ path: FilePathComponents
	) -> String {
		var result: FilePathComponents = .init(
			absolute: path.absolute,
			components: []
		)
		
		for component in path.components {
			switch component.0 {
				case ".":
					break
					
				case "..":
					if result.components.count > 0 {
						result.components.removeLast()
					}

				default:
					result.components.append(component)
			}
		}
		
		return result.build()
	}
	
	public static func splitPath(
		_ string: String
	) -> (String, Substring?) {
		let path: FilePathComponents = .parse(string)

		//- ルートの場合
		
		if path.components.count == 0 {
			return (path.build(), nil)
		}
		
		//- 非ルートの場合

		let (directory, file) = path.components.divide(last: 1)

		assert(file.count <= 1)
		
		return (
			(path.absolute ? "/" : "") + directory.map{$0.0}.joined(separator: "/"),
			file.get(at: 0)?.0
		)
	}

}
