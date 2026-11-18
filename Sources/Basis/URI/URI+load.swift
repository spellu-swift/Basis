#if os(macOS) || canImport(Glibc)


extension URI {

	///
	/// URIが指す内容を読み込む。
	///
	/// - file: ローカルのファイルを読み込む。リモートホストは扱わない。
	/// - http, https: `curl`コマンドでGETする。
	///   リダイレクトに従い、4xxと5xxの応答は失敗とする。
	///   リダイレクト先もhttpとhttpsに限る。
	///
	/// - timeout: http, httpsの全体の制限時間（秒）。nilの場合は制限しない。
	///
	public func load(
		timeout: Double? = nil,
	) throws -> Binary {
		switch scheme?.lowercased() {
		case "file":
			guard
				let filePath
			else { throw GeneralError.notSupported }

			return try File(at: filePath).load()

		case "http", "https":
			let process: Subprocess
			= try .execute(Self.curlArguments(asString, timeout: timeout))

			process.closeInput()

			return try process.wait().asBinary

		default:
			throw GeneralError.notSupported
		}
	}

	/// GETするcurlコマンドの引数。
	static func curlArguments(
		_ url: String,
		timeout: Double?,
	) throws -> [String] {
		var arguments: [String] = [
			"curl",
			"--fail",
			"--silent",
			"--show-error",
			"--location",
			"--proto", "=http,https",
			"--proto-redir", "=http,https",
		]

		if let timeout {
			// curlは0を無制限として扱うので、正の有限値だけを受け付ける。
			guard
				timeout > 0,
				timeout.isFinite
			else { throw GeneralError.unexpectedValue("timeout: \(timeout)") }

			arguments += ["--max-time", "\(timeout)"]
		}

		// --urlで渡すと、-で始まるURLもオプションとして解釈されない。
		arguments += ["--url", url]

		return arguments
	}

}

#endif
