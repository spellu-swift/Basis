@testable import Basis


private let textEncodings: [TextEncoding] = [
	.utf8,
	.utf16(.big),
	.utf16(.little),
	.utf32(.big),
	.utf32(.little),
]


@Test
func text_encoding_known_byte_sequences() throws {
	let examples: [(TextEncoding, [UInt8])] = [
		(.utf8, [0x41, 0xF0, 0x9F, 0x99, 0x83]),
		(.utf16(.big), [0x00, 0x41, 0xD8, 0x3D, 0xDE, 0x43]),
		(.utf16(.little), [0x41, 0x00, 0x3D, 0xD8, 0x43, 0xDE]),
		(.utf32(.big), [0x00, 0x00, 0x00, 0x41, 0x00, 0x01, 0xF6, 0x43]),
		(.utf32(.little), [0x41, 0x00, 0x00, 0x00, 0x43, 0xF6, 0x01, 0x00]),
	]

	for (encoding, bytes) in examples {
		#expect("A🙃".encode(encoding: encoding).asBytes == bytes)
		#expect(try Binary(bytes).decode(encoding: encoding) == "A🙃")
	}
}


@Test
func text_encoding_preserves_scalars_and_line_endings() throws {
	let examples = ["", "日本語🙃", "A\0e\u{301}\r\nB\rC\n", "\u{FFFF}\u{10FFFF}"]

	for encoding in textEncodings {
		for text in examples {
			for bom in [false, true] {
				let binary = text.encode(encoding: encoding, bom: bom)
				let decoded = try binary.decode(encoding: encoding)

				#expect(decoded.unicodeScalars.map(\.value) == text.unicodeScalars.map(\.value))
			}
		}
	}

	#expect("日本語".encode().asBytes == Array("日本語".utf8))
	#expect(try "日本語".encode().decode() == "日本語")
}


@Test
func text_decoding_detects_and_optionally_preserves_bom() throws {
	let examples: [(TextEncoding, [UInt8])] = [
		(.utf8, [0xEF, 0xBB, 0xBF]),
		(.utf16(.big), [0xFE, 0xFF]),
		(.utf16(.little), [0xFF, 0xFE]),
		(.utf32(.big), [0x00, 0x00, 0xFE, 0xFF]),
		(.utf32(.little), [0xFF, 0xFE, 0x00, 0x00]),
	]

	for (encoding, bom) in examples {
		let binary = "A\u{FEFF}B".encode(encoding: encoding, bom: true)
		#expect(binary.asBytes.starts(with: bom))
		#expect(try binary.decode() == "A\u{FEFF}B")
		#expect(try binary.decode(removeBOM: false) == "\u{FEFF}A\u{FEFF}B")
		#expect(try Binary(bom).decode() == "")
	}
}


@Test
func text_decoding_explicit_utf16_bom_before_nul() throws {
	let text = "\0A"
	let encoding: TextEncoding = .utf16(.little)
	let binary = text.encode(encoding: encoding, bom: true)

	#expect(binary.asBytes == [0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00])
	#expect(try binary.decode(encoding: encoding) == text)
	#expect(try binary.decode(encoding: encoding, removeBOM: false) == "\u{FEFF}\0A")
}


@Test
func text_decoding_rejects_conflicting_bom() {
	let binary = "A".encode(encoding: .utf16(.big), bom: true)

	for policy: TextDecodingPolicy in [.strict, .replaceInvalid] {
		#expect(throws: TextDecodingError.conflictingBOM(expected: .utf8, detected: .utf16(.big))) {
			try binary.decode(encoding: .utf8, policy: policy)
		}
		#expect(throws: TextDecodingError.conflictingBOM(expected: .utf16(.little), detected: .utf16(.big))) {
			try binary.decode(encoding: .utf16(.little), policy: policy)
		}
	}
}


@Test
func text_decoding_utf8_invalid_sequences() throws {
	let invalid: [[UInt8]] = [
		[0xFF], [0x80], [0xC0, 0x80], [0xE1, 0x80],
		[0xED, 0xA0, 0x80], [0xF4, 0x90, 0x80, 0x80],
	]

	for bytes in invalid {
		#expect(throws: TextDecodingError.invalidSequence(.utf8)) {
			try Binary(bytes).decode()
		}
	}

	#expect(try Binary([0x41, 0xFF, 0x42]).decode(policy: .replaceInvalid) == "A\u{FFFD}B")
	#expect(try Binary([0xE1, 0x80, 0x41]).decode(policy: .replaceInvalid) == "\u{FFFD}A")
}


@Test
func text_decoding_utf16_invalid_sequences_and_truncated_units() throws {
	let examples: [(TextEncoding, [UInt8], String)] = [
		(.utf16(.big), [0xD8, 0x00, 0x00, 0x41], "\u{FFFD}A"),
		(.utf16(.little), [0x00, 0xDC, 0x41, 0x00], "\u{FFFD}A"),
		(.utf16(.big), [0x00, 0x41, 0x00], "A\u{FFFD}"),
		(.utf16(.little), [0x41, 0x00, 0x00], "A\u{FFFD}"),
		(.utf16(.little), [0x00, 0xD8], "\u{FFFD}"),
	]

	for (encoding, bytes, replacement) in examples {
		#expect(throws: TextDecodingError.invalidSequence(encoding)) {
			try Binary(bytes).decode(encoding: encoding)
		}
		#expect(try Binary(bytes).decode(encoding: encoding, policy: .replaceInvalid) == replacement)
	}
}


@Test
func text_decoding_utf32_invalid_scalars_and_truncated_units() throws {
	let examples: [(TextEncoding, [UInt8])] = [
		(.utf32(.big), [0x00, 0x00, 0xD8, 0x00]),
		(.utf32(.little), [0x00, 0x00, 0x11, 0x00]),
		(.utf32(.little), [0xFF, 0xFF, 0xFF, 0xFF]),
		(.utf32(.big), [0x00]),
		(.utf32(.big), [0x00, 0x00]),
		(.utf32(.big), [0x00, 0x00, 0x00]),
	]

	for (encoding, bytes) in examples {
		#expect(throws: TextDecodingError.invalidSequence(encoding)) {
			try Binary(bytes).decode(encoding: encoding)
		}
		#expect(try Binary(bytes).decode(encoding: encoding, policy: .replaceInvalid) == "\u{FFFD}")
	}
}
