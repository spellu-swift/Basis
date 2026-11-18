

extension URI {

	/// 先頭のルート区切りを除き、空のセグメントと末尾の区切りを保持する。
	/// 各セグメントはPercent Encodingされたまま返す。
	public var pathSegments: [String] {
		guard
			path.isNotEmpty
		else { return [] }

		let content: Substring
		= path.hasPrefix("/") ? path.dropFirst() : path[...]

		return content.split(
			separator: "/",
			omittingEmptySubsequences: false,
		).map(String.init)
	}

	/// 末尾の区切りは無視する。空パスとルートでは空文字列を返す。
	public var lastPathComponent: String {
		path.split(separator: "/").last.map(String.init) ?? ""
	}

	/// 未エンコードの単一要素を追加する。要素内の`/`は`%2F`になる。
	public func appendingPathComponent(
		_ component: String,
	) -> URI {
		var result: URI = self

		let encoded: String
		= Self.percentEncode(component, component: .pathSegment)

		if path.isEmpty {
			result.path = (authority != nil ? "/" : "") + encoded
		}
		else {
			result.path += (path.hasSuffix("/") ? "" : "/") + encoded
		}

		result.protectPathSyntax()

		return result
	}

	internal mutating func protectPathSyntax() {
		guard
			authority == nil
		else { return }

		// 操作後のパスをauthorityやschemeとして誤認させない。
		if path.hasPrefix("//") {
			path = "/." + path
		}
		else if
			scheme == nil,
			path.hasPrefix("/") == false,
			path.prefix(while: { $0 != "/" }).contains(":")
		{
			path = "./" + path
		}
	}

	public func deletingLastPathComponent() -> URI {
		var result: URI = self

		var remaining: Substring = path[...]

		while remaining.hasSuffix("/") {
			remaining = remaining.dropLast()
		}

		if
			let slash = remaining.lastIndex(of: "/")
		{
			result.path = String(remaining[...slash])
		}
		else {
			result.path = path.hasPrefix("/") ? "/" : ""
		}

		return result
	}

}
