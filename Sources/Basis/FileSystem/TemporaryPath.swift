

enum TemporaryPath {

	// 相対パスはここで絶対化し、処理中の作業ディレクトリ変更に影響されないようにする。
	static func absolute(_ path: FilePath) -> FilePath {
		let expanded = FilePath(path.expanded)

		return expanded.absoluted
	}

	static func make(
		prefix: String,
		suffix: String = "",
		in directory: Directory?,
	) -> FilePath {
		precondition(!prefix.contains("/") && !prefix.contains("\0"))
		precondition(!suffix.contains("/") && !suffix.contains("\0"))

		let base = absolute(directory?.path ?? Backbone.temporaryDirectory)

		return base.appending("\(prefix)-\(UUID.new)\(suffix)")
	}

}
