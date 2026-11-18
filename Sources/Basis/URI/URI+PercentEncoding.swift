

extension URI {

	public enum Component: Sendable {

		case userInfo
		case host
		case path
		case pathSegment
		case query
		case fragment

	}

	/// 生の文字列をエンコードする。既存の`%`も`%25`に変換する。
	public static func percentEncode(
		_ string: String,
		component: Component,
	) -> String {
		let hex: [UInt8]
		= Array("0123456789ABCDEF".utf8)
		var result: [UInt8] = []

		for byte in string.utf8 {
			if isAllowed(byte, component: component) {
				result.append(byte)
			} else {
				result.append(contentsOf: [37, hex[Int(byte >> 4)], hex[Int(byte & 15)]])
			}
		}
		return String(decoding: result, as: UTF8.self)
	}

	public static func percentDecode(
		_ string: String,
	) -> String? {
		let bytes: [UInt8]
		= Array(string.utf8)
		var result: [UInt8] = []
		var index: Int = 0

		while index < bytes.count {
			if bytes[index] == 37 {
				guard index + 2 < bytes.count,
					let high = hexValue(bytes[index + 1]),
					let low = hexValue(bytes[index + 2])
				else { return nil }

				result.append(high * 16 + low)
				index += 3
			}
			else {
				result.append(bytes[index])
				index += 1
			}
		}

		// String(decoding:)は不正なUTF-8を置換するため、往復して検証する。
		let decoded: String
		= String(decoding: result, as: UTF8.self)
		return decoded.utf8.elementsEqual(result) ? decoded : nil
	}

	internal static func hexValue(
		_ byte: UInt8,
	) -> UInt8? {
		switch byte {
			case 48...57: byte - 48
			case 65...70: byte - 55
			case 97...102: byte - 87
			default: nil
		}
	}

	internal static func isUnreserved(
		_ byte: UInt8,
	) -> Bool {
		switch byte {
			case 65...90, 97...122, 48...57, 45, 46, 95, 126: true
			default: false
		}
	}

	internal static func isAllowed(
		_ byte: UInt8,
		component: Component,
	) -> Bool {
		if isUnreserved(byte) || "!$&'()*+,;=".utf8.contains(byte) { return true }

		switch component {
			case .userInfo: return byte == 58
			case .host: return false
			case .pathSegment: return byte == 58 || byte == 64
			case .path: return byte == 58 || byte == 64 || byte == 47
			case .query, .fragment: return byte == 58 || byte == 64 || byte == 47 || byte == 63
		}
	}

	internal static func isValid(
		_ string: String,
		component: Component,
	) -> Bool {
		let bytes: [UInt8]
		= string.asBytes

		var index: Int = 0

		while index < bytes.count {
			if bytes[index] == 37 {
				guard
					index + 2 < bytes.count,
					hexValue(bytes[index + 1]) != nil,
					hexValue(bytes[index + 2]) != nil
				else { return false }

				index += 3
			}
			else {
				guard
					isAllowed(bytes[index], component: component)
				else { return false }

				index += 1
			}
		}

		return true
	}

}
