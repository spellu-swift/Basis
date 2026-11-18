

extension Binary {

	/// UTF形式のバイト列を復号する。
	/// encodingの省略時はBOMから判定し、BOMがなければUTF-8として扱う。
	/// 明示した方式とBOMが矛盾する場合は、policyに関係なくエラーにする。
	/// removeBOMがfalseの場合、先頭のBOMもU+FEFFとして保持する。
	public func decode(
		encoding: TextEncoding? = nil,
		policy: TextDecodingPolicy = .strict,
		removeBOM: Bool = true,
	) throws -> String {
		let bytes = asBytes
		let resolved: TextEncoding
		let bomCount: Int

		if let encoding {
			resolved = encoding

			// 明示した方式のBOMを優先する。UTF-16LEのBOM直後のNULを
			// UTF-32LEのBOMと取り違えないようにする。
			if bytes.starts(with: encoding.bom) {
				bomCount = encoding.bom.count
			}
			else if let detected = TextEncoding.detectedBOM(in: bytes) {
				throw TextDecodingError.conflictingBOM(expected: encoding, detected: detected)
			}
			else {
				bomCount = 0
			}
		}
		else if let detected = TextEncoding.detectedBOM(in: bytes) {
			resolved = detected
			bomCount = detected.bom.count
		}
		else {
			resolved = .utf8
			bomCount = 0
		}

		let input = bytes.dropFirst(removeBOM ? bomCount : 0)
		let strict = policy == .strict

		switch resolved {
			case .utf8:
				if strict {
					guard let text = validateText(input, as: UTF8.self)
					else { throw TextDecodingError.invalidSequence(resolved) }
					return text
				}
				return String(decoding: input, as: UTF8.self)

			case .utf16(let order):
				let (units, remainder) = readTextUnits(input, width: 2, order: order)
				let words = units.map { UInt16($0) }

				if strict {
					guard remainder == 0, let text = validateText(words, as: UTF16.self)
					else { throw TextDecodingError.invalidSequence(resolved) }
					return text
				}
				return String(decoding: words, as: UTF16.self) + (remainder == 0 ? "" : "\u{FFFD}")

			case .utf32(let order):
				let (units, remainder) = readTextUnits(input, width: 4, order: order)

				if strict {
					guard remainder == 0, let text = validateText(units, as: UTF32.self)
					else { throw TextDecodingError.invalidSequence(resolved) }
					return text
				}
				return String(decoding: units, as: UTF32.self) + (remainder == 0 ? "" : "\u{FFFD}")
		}
	}
}


private func readTextUnits(
	_ bytes: ArraySlice<UInt8>,
	width: Int,
	order: Endianness,
) -> (units: [UInt32], remainder: Int) {
	let remainder = bytes.count % width
	var units: [UInt32] = []
	units.reserveCapacity(bytes.count / width)

	for offset in stride(from: 0, to: bytes.count - remainder, by: width) {
		var value: UInt32 = 0

		for index in 0..<width {
			let shift = (order == .little ? index : width - index - 1) * 8
			value |= UInt32(bytes[bytes.startIndex + offset + index]) << shift
		}

		units.append(value)
	}

	return (units, remainder)
}


// UnicodeCodecを使い、Basisの最低対応OSでも置換せずに検証する。
private func validateText<Units: Sequence, Codec: UnicodeCodec>(
	_ units: Units,
	as codec: Codec.Type,
) -> String? where Units.Element == Codec.CodeUnit {
	var iterator = units.makeIterator()
	var decoder = Codec()
	var text = ""

	while true {
		switch decoder.decode(&iterator) {
			case .scalarValue(let scalar):
				text.unicodeScalars.append(scalar)
			case .emptyInput:
				return text
			case .error:
				return nil
		}
	}
}
