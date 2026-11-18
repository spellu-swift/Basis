

extension URI {

	public struct QueryItem: Hashable, Sendable {

		public init(
			name: String,
			value: String? = nil,
		) {
			self.name = name
			self.value = value
		}

		public var name: String
		public var value: String?

	}

	/// 順序・重複・値の有無を保持し、`+`はそのまま扱う。
	/// UTF-8としてデコードできない項目はエンコードされた文字列を返す。
	public var queryItems: [QueryItem] {
		guard
			let query,
			query.isNotEmpty
		else { return [] }

		return query.split(
			separator: "&",
			omittingEmptySubsequences: false,
		).map { element in
			let parts = element.split(
				separator: "=",
				maxSplits: 1,
				omittingEmptySubsequences: false,
			)
			let name = String(parts[0])
			let value = parts.count == 2 ? String(parts[1]) : nil

			return QueryItem(
				name: Self.percentDecode(name) ?? name,
				value: value.map { Self.percentDecode($0) ?? $0 },
			)
		}
	}

	/// 項目の名前と値は未エンコードの文字列を受け取る。
	public func appendingQueryItem(
		name: String,
		value: String? = nil,
	) -> URI {
		var result: URI = self

		let item: String
		= encodeQueryComponent(name) + (value.map { "=\(encodeQueryComponent($0))" } ?? "")

		result.query = query.map {
			$0.isEmpty ? item : $0 + "&" + item
		} ?? item

		return result
	}

	/// デコード後の名前が一致する項目をすべて削除する。
	/// 残る項目の順序と表記を保持し、全項目を削除した場合はqueryをnilにする。
	public func removingQueryItems(
		named name: String,
	) -> URI {
		guard
			let query,
			query.isNotEmpty
		else { return self }

		let remaining: [Substring]
		= query.split(
			separator: "&",
			omittingEmptySubsequences: false,
		).filter { element in
			let encodedName: String
			= String(element.prefix(while: { $0 != "=" }))
			return (Self.percentDecode(encodedName) ?? encodedName) != name
		}

		var result: URI = self
		result.query = remaining.isEmpty ? nil : remaining.joined(separator: "&")
		return result
	}

}
