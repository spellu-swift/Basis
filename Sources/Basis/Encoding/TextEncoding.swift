

/// テキストをバイト列として表す符号化方式。
public enum TextEncoding : Sendable, Hashable {

	case utf8
	case utf16(Endianness)
	case utf32(Endianness)

}


/// 不正なバイト列を復号するときの処理方針。
public enum TextDecodingPolicy : Sendable, Hashable {

	case strict
	case replaceInvalid

}


public enum TextDecodingError : ProgramError, Sendable {

	case invalidSequence(TextEncoding)
	case conflictingBOM(expected: TextEncoding, detected: TextEncoding)

}


extension TextEncoding {

	var bom: [UInt8] {
		switch self {
			case .utf8: [0xEF, 0xBB, 0xBF]
			case .utf16(.big): [0xFE, 0xFF]
			case .utf16(.little): [0xFF, 0xFE]
			case .utf32(.big): [0x00, 0x00, 0xFE, 0xFF]
			case .utf32(.little): [0xFF, 0xFE, 0x00, 0x00]
		}
	}

	static func detectedBOM(in bytes: [UInt8]) -> Self? {
		// UTF-32LEのBOMはUTF-16LEのBOMを含むため、長い方を先に判定する。
		for encoding: Self in [.utf32(.big), .utf32(.little), .utf8, .utf16(.big), .utf16(.little)] {
			if bytes.starts(with: encoding.bom) { return encoding }
		}

		return nil
	}

}
