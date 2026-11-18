

extension String {

	/// UTF形式のバイト列を生成する。BOMの付加は既定で無効。
	/// 改行とUnicodeスカラーの並びは変更しない。
	public func encode(
		encoding: TextEncoding = .utf8,
		bom: Bool = false,
	) -> Binary {
		var bytes = bom ? encoding.bom : []

		switch encoding {
			case .utf8:
				bytes.append(contentsOf: utf8)

			case .utf16(let order):
				for unit in utf16 {
					appendTextUnit(UInt32(unit), width: 2, order: order, to: &bytes)
				}

			case .utf32(let order):
				for scalar in unicodeScalars {
					appendTextUnit(scalar.value, width: 4, order: order, to: &bytes)
				}
		}

		return Binary(bytes)
	}
}


private func appendTextUnit(
	_ value: UInt32,
	width: Int,
	order: Endianness,
	to bytes: inout [UInt8],
) {
	for index in 0..<width {
		let shift = (order == .little ? index : width - index - 1) * 8
		bytes.append(UInt8(truncatingIfNeeded: value >> shift))
	}
}
