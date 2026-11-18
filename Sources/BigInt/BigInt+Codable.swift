// MARK: Codable


/// 10 進数の文字列として書き出し、10 進数の文字列から読み込む。
/// JSON の数値は多くの処理系で精度が落ちるため、数値にはしない。
extension BigInt: Codable {

	public init(
		from decoder: any Decoder,
	) throws {
		let container: any SingleValueDecodingContainer = try decoder
			.singleValueContainer()
		let text: String = try container.decode(String.self)

		guard
			let value = BigInt(text)
		else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "BigIntとして解析できない文字列: \(text)"
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
