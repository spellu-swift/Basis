

public struct Hex {
	
	@inlinable
	public static func encode(
		_ bytes: [UInt8]
	) -> String {
		encode(ArraySlice(bytes))
	}
	
	@inlinable
	public static func encode(
		_ bytes: ArraySlice<UInt8>
	) -> String {
		var buffer: String = ""
		
		for byte in bytes {
			buffer.append(String(byte >> 4, radix: 16, uppercase: true))
			buffer.append(String(byte & 0xF, radix: 16, uppercase: true))
		}
		
		return buffer
	}
	
	public static func decode(
		_ string: String
	) throws -> [UInt8] {
		precondition(string.count.isMultiple(of: 2))

		let byteCount: Int = string.count / 2

		var bytes: [UInt8] = .init(capacity: byteCount)
		
		for index in 0..<byteCount {
			let c: Substring = string[index * 2...index * 2 + 1]

			guard
				let byte = UInt8(c, radix: 16)
			else {
				throw DecodingError.dataCorrupted(.init(
					codingPath: [],
					debugDescription: "Illegal data.",
					underlyingError: nil)
				)
			}

			bytes.append(byte)
		}
		
		return bytes
	}
	
	
}

