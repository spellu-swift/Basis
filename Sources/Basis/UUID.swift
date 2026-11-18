

public typealias uuid_t = (
	UInt8, UInt8, UInt8, UInt8,
	UInt8, UInt8, UInt8, UInt8,
	UInt8, UInt8, UInt8, UInt8,
	UInt8, UInt8, UInt8, UInt8
)


public struct UUID : Sendable {
	

	@inlinable
	public static var zero: UUID {
		UUID([UInt8](repeating: 0, count: 16))
	}
	
	
	/// Create a new UUID with RFC 4122 version 4 random bytes
	public static var new: UUID {
		var generator = SystemRandomNumberGenerator()
		var bytes: [UInt8] = (0 ..< 16).map { _ in generator.next() }

		// バージョン 4
		bytes[6] = (bytes[6] & 0x0F) | 0x40
		// バリアント RFC 4122
		bytes[8] = (bytes[8] & 0x3F) | 0x80

		return UUID(bytes)
	}
	
	
	private init(
	) {
		fatalError()
	}
	

	@inlinable
	public init(
		_ uuid: uuid_t
	) {
		self.bytes = withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 16) { (buffer: UnsafeMutableBufferPointer<UInt8>) in
			buffer.baseAddress!.withMemoryRebound(to: uuid_t.self, capacity: 1) {
				$0.pointee = uuid
			}
			
			return [UInt8](buffer)
		}
	}
	
	
	@inlinable
	public init(
		_ bytes: [UInt8]
	) {
		precondition(bytes.count == 16)
		
		self.bytes = bytes
	}
	

	public enum StringKind {
		// such as "E621E1F8C36C495A93FC0C247A3E6E5F"
		case hex
		
		// such as "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
		case uuid
	}
	

	public init?(
		_ string: String
	) {
		switch string.count {
			case 32:
				guard let value: Self = .init(.hex, string)
				else { return nil }
				self = value

			case 36:
				guard let value: Self = .init(.uuid, string)
				else { return nil }
				self = value

			default:
				return nil
		}
	}


	public init?(
		_ kind: StringKind,
		_ string: String
	) {
		switch kind {
			case .hex:
				guard
					let bytes: [UInt8] = try? Hex.decode(string),
					bytes.count == 16
				else { return nil }
				
				self.init(bytes)

			case .uuid:
				guard
					check(string),
					let bytes: [UInt8] = try? Hex.decode(string.filter({$0 != "-"}))
				else { return nil }

				self.init(bytes)
		}
	}
	
	
	@usableFromInline
	let bytes: [UInt8]

	
	@inlinable
	public var uuid: uuid_t {
		bytes.withUnsafeBytes {
			$0.baseAddress!.load(as: uuid_t.self)
		}
	}
	
	
	@inlinable
	public var asBytes: [UInt8] {
		bytes
	}

	
	public func asString(
		_ kind: StringKind
	) -> String {
		switch kind {
			case .hex:
				return Hex.encode(bytes)
				
			case .uuid:
				return Hex.encode(bytes[0..<4]) + "-"
				+ Hex.encode(bytes[4..<6]) + "-"
				+ Hex.encode(bytes[6..<8]) + "-"
				+ Hex.encode(bytes[8..<10]) + "-"
				+ Hex.encode(bytes[10..<16])
		}
	}


}


extension UUID : Equatable {
	
	
	@inlinable
	public static func ==(
		lhs: UUID,
		rhs: UUID
	) -> Bool {
		lhs.bytes == rhs.bytes
	}
	
	
}


extension UUID : Hashable {
	
	
	@inlinable
	public func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(bytes)
	}
	
	
}



extension UUID : CustomStringConvertible {
	
	
	@inlinable
	public var description: String {
		asString(.uuid)
	}
	
	
}


extension UUID : Codable {


	public init(
		from decoder: Decoder
	) throws {
		let container = try decoder.singleValueContainer()
		let uuidString = try container.decode(String.self)
		
		guard let uuid = UUID(.uuid, uuidString) else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Attempted to decode UUID from invalid UUID string."
				)
			)
		}
		
		self = uuid
	}
	

	public func encode(
		to encoder: Encoder
	) throws {
		var container = encoder.singleValueContainer()

		try container.encode(asString(.uuid))
	}


}




private func check(
	_ string: String
) -> Bool {
	string.wholeMatch(
		of: #/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/#
	) != nil
}
