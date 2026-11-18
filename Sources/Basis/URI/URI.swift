

///
/// URIは以下の構成要素からなる。
///
///     [scheme:][//authority]path[?query][#fragment]
///
/// - `scheme`: URIのスキーム。省略可能。
/// - `authority`: ユーザー情報、ホスト、ポートからなる認証局部。省略可能。
/// - `path`: リソースを識別するパス。
/// - `query`: クエリ文字列。省略可能。
/// - `fragment`: フラグメント識別子。省略可能。
///
/// 各構成要素は変更可能であり、Percent Encodingされた文字列として保持する。
/// `authority`が`nil`の場合は`//`を出力せず、空のauthorityとは区別する。
///
/// URIの構文および相対参照の解決はRFC 3986に従う。
/// ファイルURIの構文はRFC 8089に従う。
///
/// - SeeAlso: [RFC 3986 - Uniform Resource Identifier (URI): Generic Syntax](https://www.rfc-editor.org/rfc/rfc3986)
/// - SeeAlso: [RFC 8089 - The "file" URI Scheme](https://www.rfc-editor.org/rfc/rfc8089)
///
public struct URI : Hashable, Codable, Sendable {

	public init(
		scheme: String? = nil,
		authority: Authority? = nil,
		path: String,
		query: String? = nil,
		fragment: String? = nil,
	) {
		self.scheme = scheme
		self.authority = authority
		self.path = path
		self.query = query
		self.fragment = fragment
	}

	public var scheme: String?
	public var authority: Authority?
	public var path: String
	public var query: String?
	public var fragment: String?

}


extension URI : ExpressibleByStringLiteral {

	public init(
		stringLiteral value: StringLiteralType,
	) {
		self = .init(value)!
	}

}


extension URI {

	public struct Authority: Hashable, Codable, Sendable {
		
		public init(
			userInfo: String? = nil,
			host: String,
			port: String? = nil,
		) {
			self.userInfo = userInfo
			self.host = host
			self.port = port
		}

		public var userInfo: String?
		public var host: String
		public var port: String?

	}

}


extension URI {

	public var asString: String {
		(scheme.map { "\($0):" } ?? "") +
		(authority.map { "//\($0.asString)" } ?? "") +
		path +
		(query.map { "?\($0)" } ?? "") +
		(fragment.map { "#\($0)" } ?? "")
	}

	public var isAbsolute: Bool { scheme != nil }

	public var isRelative: Bool { scheme == nil }

	public var host: String? { authority?.host }
	
}


extension URI : CustomStringConvertible {

	@inlinable
	public var description: String {
		asString
	}

}
