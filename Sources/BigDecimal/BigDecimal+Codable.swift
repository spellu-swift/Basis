// MARK: Codable


/// `description`（GDA の to-scientific-string）の文字列として書き出し、
/// 文字列から読み込む。値とスケールが往復で保たれる。
/// JSON の数値は多くの処理系で精度が落ちるため、数値にはしない。
extension BigDecimal: Codable {

	public init(
		from decoder: any Decoder,
	) throws {
		let container: any SingleValueDecodingContainer = try decoder
			.singleValueContainer()
		let text: String = try container.decode(String.self)

		guard
			let value = BigDecimal(text)
		else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "BigDecimalとして解析できない文字列: \(text)"
			)
		}

		self = value
	}

	public func encode(
		to encoder: any Encoder,
	) throws {
		var container: any SingleValueEncodingContainer = encoder
			.singleValueContainer()
		try container.encode(description)
	}

}
