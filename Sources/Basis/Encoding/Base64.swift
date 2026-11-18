

public enum Base64Error : ProgramError {
	case invalidInput
	case invalidCharacterCount
}


///
/// Base64 エンコード/デコード
///
public class Base64 {
		
	private static let base64Padding : UInt8 = 61 // =
	
	public struct EncodingOptions : OptionSet, Sendable {
		public typealias RawValue = UInt
		
		public init(
			rawValue: UInt,
		) {
			self.rawValue = rawValue
		}
		
		public var rawValue: RawValue

		public static let lineLength64Characters: Self = .init(rawValue: 1 << 0)
		public static let lineLength76Characters: Self = .init(rawValue: 1 << 1)
		public static let endLineWithCarriageReturn: Self = .init(rawValue: 1 << 4)
		public static let endLineWithLineFeed: Self = .init(rawValue: 1 << 5)
	}
	

	public struct DecodingOptions : OptionSet, Sendable {
		public typealias RawValue = UInt
		
		public init(
			rawValue: UInt
		) {
			self.rawValue = rawValue
		}
		
		public var rawValue: RawValue
		
		public static let ignoreUnknownCharacters: Self = .init(rawValue: 1 << 0)
	}
	
	
	public static func estimate(
		length: Int,
	) -> Int {
		// Worst case allow for 64bytes + \r\n per line  48 input bytes => 66 output bytes
		return ((length + 47) * 66) / 48
	}

	
	public static func encode(
		input: UnsafeRawBufferPointer,
		output: UnsafeMutableRawBufferPointer,
		options: EncodingOptions,
	) -> Int {
		// Use a StaticString for lookup of values 0-63 -> ASCII values
		let base64Chars = StaticString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
		assert(base64Chars.utf8CodeUnitCount == 64)
		assert(base64Chars.hasPointerRepresentation)
		assert(base64Chars.isASCII)
		let base64CharsPtr = base64Chars.utf8Start
		
		let lineLength: Int
		var currentLineCount = 0
		let separatorByte1: UInt8
		var separatorByte2: UInt8? = nil
		
		if options.isEmpty {
			lineLength = 0
			separatorByte1 = 0
		} else {
			if options.contains(.lineLength64Characters) {
				lineLength = 64
			} else if options.contains(.lineLength76Characters) {
				lineLength = 76
			} else {
				lineLength = 0
			}
			
			if options.contains(.endLineWithCarriageReturn) && options.contains(.endLineWithLineFeed) {
				separatorByte1 = UInt8(ascii: "\r")
				separatorByte2 = UInt8(ascii: "\n")
			} else if options.contains(.endLineWithCarriageReturn) {
				separatorByte1 = UInt8(ascii: "\r")
			} else if options.contains(.endLineWithLineFeed) {
				separatorByte1 = UInt8(ascii: "\n")
			} else {
				separatorByte1 = UInt8(ascii: "\r")
				separatorByte2 = UInt8(ascii: "\n")
			}
		}
		
		func lookupBase64Value(
			_ value: UInt16,
		) -> UInt32 {
			let byte = base64CharsPtr[Int(value & 63)]
			return UInt32(byte)
		}
		
		// Read three bytes at a time, which convert to 4 ASCII characters, allowing for byte2 and byte3 being nil
		
		var inputIndex = 0
		var outputIndex = 0
		var bytesLeft = input.count
		
		while bytesLeft > 0 {
			let byte1 = input[inputIndex]
			
			// outputBytes is a UInt32 to allow 4 bytes to be written out at once.
			var outputBytes = lookupBase64Value(UInt16(byte1 >> 2))
			
			if bytesLeft > 2 {
				// This is the main loop converting 3 bytes at a time.
				let byte2 = input[inputIndex + 1]
				let byte3 = input[inputIndex + 2]
				var value = UInt16(byte1 & 0x3) << 8
				value |= UInt16(byte2)
				
				let outputByte2 = lookupBase64Value(value >> 4)
				outputBytes |= (outputByte2 << 8)
				value = (value << 8) | UInt16(byte3)
				
				let outputByte3 = lookupBase64Value(value >> 6)
				outputBytes |= (outputByte3 << 16)
				
				let outputByte4 = lookupBase64Value(value)
				outputBytes |= (outputByte4 << 24)
				inputIndex += 3
			}
			else {
				// This runs once at the end of there were 1 or 2 bytes left, byte1 having already been read.
				// Read byte2 or 0 if there isnt another byte
				let byte2 = bytesLeft == 1 ? 0 : input[inputIndex + 1]
				var value = UInt16(byte1 & 0x3) << 8
				value |= UInt16(byte2)
				
				let outputByte2 = lookupBase64Value(value >> 4)
				outputBytes |= (outputByte2 << 8)
				
				let outputByte3 = bytesLeft == 1 ? UInt32(self.base64Padding) : lookupBase64Value(value << 2)
				outputBytes |= (outputByte3 << 16)
				outputBytes |= (UInt32(self.base64Padding) << 24)
				inputIndex += bytesLeft
				assert(inputIndex == input.count)
			}
			
			// The lowest byte of outputBytes needs to be stored at the lowest address, so make sure
			// the bytes are in the correct order on big endian CPUs.
			outputBytes = outputBytes.littleEndian
			
			// The output isnt guaranteed to be aligned on a 4 byte boundary if EOL markers (CR, LF or CRLF)
			// are written out so use .copyMemory() for safety. On x86 this still translates to a single store
			// anyway.
			output.baseAddress!.advanced(by: outputIndex).copyMemory(from: &outputBytes, byteCount: 4)
			outputIndex += 4
			bytesLeft = input.count - inputIndex
			
			if lineLength != 0 {
				// Add required EOL markers.
				currentLineCount += 4
				assert(currentLineCount <= lineLength)
				
				if currentLineCount == lineLength && bytesLeft > 0 {
					output[outputIndex] = separatorByte1
					outputIndex += 1
					
					if let byte2 = separatorByte2 {
						output[outputIndex] = byte2
						outputIndex += 1
					}
					currentLineCount = 0
				}
			}
		}
		
		// Return the number of ASCII bytes written to the buffer
		return outputIndex
	}
		
	public static func decode(
		input: UnsafeRawBufferPointer,
		output: UnsafeMutableRawBufferPointer,
		options: DecodingOptions = [],
	) throws -> Int {
		// This table maps byte values 0-127, input bytes >127 are always invalid.
		// Map the ASCII characters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" -> 0...63
		// Map '=' (ASCII 61) to 0x40.
		// All other values map to 0x7f. This allows '=' and invalid bytes to be checked together by testing bit 6 (0x40).
		let base64Decode: StaticString = """
\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\
\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\
\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{3e}\u{7f}\u{7f}\u{7f}\u{3f}\
\u{34}\u{35}\u{36}\u{37}\u{38}\u{39}\u{3a}\u{3b}\u{3c}\u{3d}\u{7f}\u{7f}\u{7f}\u{40}\u{7f}\u{7f}\
\u{7f}\u{00}\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{09}\u{0a}\u{0b}\u{0c}\u{0d}\u{0e}\
\u{0f}\u{10}\u{11}\u{12}\u{13}\u{14}\u{15}\u{16}\u{17}\u{18}\u{19}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\
\u{7f}\u{1a}\u{1b}\u{1c}\u{1d}\u{1e}\u{1f}\u{20}\u{21}\u{22}\u{23}\u{24}\u{25}\u{26}\u{27}\u{28}\
\u{29}\u{2a}\u{2b}\u{2c}\u{2d}\u{2e}\u{2f}\u{30}\u{31}\u{32}\u{33}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}
"""
		assert(base64Decode.isASCII)
		assert(base64Decode.utf8CodeUnitCount == 128)
		assert(base64Decode.hasPointerRepresentation)
		
		let ignoreUnknown = options.contains(.ignoreUnknownCharacters)
		if !ignoreUnknown && !input.count.isMultiple(of: 4) {
			throw Base64Error.invalidInput
		}
		
		var outputIndex = 0
		
		func append(_ byte: UInt8) {
			assert(outputIndex < output.count)

			output.storeBytes(of: byte, toByteOffset: outputIndex, as: UInt8.self)
			outputIndex += 1
		}
		
		var currentByte: UInt8 = 0
		var validCharacterCount: Int = 0
		var paddingCount: Int = 0
		var index: Int = 0
		var error: Bool = false
		
		for base64Char in input {
			var value: UInt8 = 0
			
			var invalid: Bool = false

			if base64Char >= base64Decode.utf8CodeUnitCount {
				invalid = true
			}
			else {
				value = base64Decode.utf8Start[Int(base64Char)]

				if value & 0x40 == 0x40 {       // Input byte is either '=' or an invalid value.
					if value == 0x7f {
						invalid = true
					}
					else if value == 0x40 {   // '=' padding at end of input.
						paddingCount += 1
						continue
					}
				}
			}
			
			if invalid {
				if ignoreUnknown {
					continue
				}
				else {
					error = true
					break
				}
			}

			validCharacterCount += 1
			
			// Padding found in the middle of the sequence is invalid.
			if paddingCount > 0 {
				error = true
				break
			}
			
			switch index {
				case 0:
					currentByte = (value << 2)
				case 1:
					currentByte |= (value >> 4)
					append(currentByte)
					currentByte = (value << 4)
				case 2:
					currentByte |= (value >> 2)
					append(currentByte)
					currentByte = (value << 6)
				case 3:
					currentByte |= value
					append(currentByte)
					index = -1
				default:
					fatalError()
			}
			
			index += 1
		}
		
		guard
			error == false,
			(validCharacterCount + paddingCount) % 4 == 0
		else { throw Base64Error.invalidCharacterCount }

		return outputIndex
	}

}
