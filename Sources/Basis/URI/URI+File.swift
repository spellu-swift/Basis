

extension URI {
	
	/// 未エンコードのパスから生成する。相対パスは現在の作業ディレクトリを基準にする。
	public static func file(
		_ path: String,
	) -> Self {
		let absolutePath: String
		= path.hasPrefix("/") ? path : FilePath(noCheck: path).absoluted.asString

		return .init(
			scheme: "file",
			authority: .init(host: ""),
			path: percentEncode(absolutePath, component: .path),
		)
	}

	public static func file(
		_ path: FilePath,
	) -> Self {
		file(path.asString)
	}

	public var isFileURI: Bool {
		scheme?.lowercased() == "file"
	}

	/// ローカルの絶対パスだけを返す。
	/// リモートホストや不正なUTF-8は変換しない。
	public var filePath: FilePath? {
		guard
			isFileURI,
			path.hasPrefix("/"),
			authority == nil || (
				authority?.userInfo == nil
				&& authority?.port == nil
				&& (authority?.host == "" || authority?.host.lowercased() == "localhost")
			),
			path.lowercased().contains("%2f") == false
		else { return nil }

		guard
			let decoded = Self.percentDecode(path),
			decoded.utf8.contains(0) == false
		else { return nil }

		return FilePath(noCheck: decoded)
	}

}


