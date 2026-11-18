

extension URI {

	/// URI文字列から構築する
	public init?(
		_ string: String,
	) {
		// RFC 3986 Appendix Bの分解に、構成要素ごとの構文検証を組み合わせる。
		guard
			let match = string.wholeMatch(
				of: #/(?:(?<scheme>[A-Za-z][A-Za-z0-9+.-]*):)?(?://(?<authority>[^/?#]*))?(?<path>[^?#]*)(?:\?(?<query>[^#]*))?(?:\#(?<fragment>.*))?/#,
			)
		else { return nil }

		let scheme: String?
		= match.scheme.map(String.init)

		let path: String
		= String(match.path)

		let query: String?
		= match.query.map(String.init)

		let fragment: String?
		= match.fragment.map(String.init)

		let authority: Authority?
		if let rawAuthority = match.authority {
			guard let parsed = Authority(String(rawAuthority)) else { return nil }
			authority = parsed
		}
		else {
			authority = nil
		}

		guard
			Self.isValid(path, component: .path),
			query.map({ Self.isValid($0, component: .query) }) ?? true,
			fragment.map({ Self.isValid($0, component: .fragment) }) ?? true
		else { return nil }

		if authority != nil {
			guard
				path.isEmpty || path.hasPrefix("/")
			else { return nil }
		}
		else {
			guard
				!path.hasPrefix("//")
			else { return nil }

			if scheme == nil, !path.hasPrefix("/") {
				guard
					!path.prefix(while: { $0 != "/" }).contains(":")
				else { return nil }
			}
		}

		self.init(
			scheme: scheme,
			authority: authority,
			path: path,
			query: query,
			fragment: fragment,
		)
	}

	/// URI文字列を解析する
	@inlinable
	public static func parse(
		_ string: String,
	) throws -> Self {
		guard
			let uri = Self(string)
		else { throw GeneralError.invalidFormat(string) }

		return uri
	}

}
