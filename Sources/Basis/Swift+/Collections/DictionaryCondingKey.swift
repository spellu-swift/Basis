

public struct DictionaryCodingKey : Swift.CodingKey {
	
	
	public init(
		stringValue: String
	) {
		self.stringValue = stringValue
	}
	
	
	public init(
		intValue: Int
	) {
		self.stringValue = "\(intValue)"
		self.intValue = intValue
	}
	
	
	public init(
		codingKey: any Swift.CodingKey
	) {
		self.stringValue = codingKey.stringValue
		self.intValue = codingKey.intValue
	}
	
	
	public var stringValue: String
	
	public var intValue: Int? /* Not used */
	
	
}


public protocol CodingKeyRepresentable {
	
	
	init?(
		codingKey: any CodingKey
	)
	

	var codingKey: any CodingKey { get }
	
	
}


extension String : CodingKeyRepresentable {

	
	public init?(
		codingKey: any CodingKey
	) {
		self = codingKey.stringValue
	}
	
	
	public var codingKey: any CodingKey {
		DictionaryCodingKey(stringValue: self)
	}

	
}


extension FixedWidthInteger where Self : CodingKeyRepresentable {
	
	
	public init?(
		codingKey: any CodingKey
	) {
		if let value = Self(codingKey.stringValue) {
			self = value
		} else {
			return nil
		}
	}
	
	
	public var codingKey: any CodingKey {
		DictionaryCodingKey(stringValue: String(self))
	}
	
	
}


extension Int8 : CodingKeyRepresentable {}
extension Int16 : CodingKeyRepresentable {}
extension Int32 : CodingKeyRepresentable {}
extension Int64 : CodingKeyRepresentable {}
extension Int : CodingKeyRepresentable {}
extension UInt8 : CodingKeyRepresentable {}
extension UInt16 : CodingKeyRepresentable {}
extension UInt32 : CodingKeyRepresentable {}
extension UInt64 : CodingKeyRepresentable {}
extension UInt : CodingKeyRepresentable {}


extension RawRepresentable where Self : CodingKeyRepresentable, RawValue : CodingKeyRepresentable {


	public init?(
		codingKey: any CodingKey
	) {
		if let value = RawValue(codingKey: codingKey) {
			if let value = Self(rawValue: value) {
				self = value
			} else {
				return nil
			}
		} else {
			return nil
		}
	}
	
	
	public var codingKey: any CodingKey {
		rawValue.codingKey
	}
	
	
}


//@available(SwiftStdlib 5.6, *)
//@available(macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4, *)
extension UUID : CodingKeyRepresentable {
	
	
	public init?(
		codingKey: any CodingKey
	) {
		if let value = Self(codingKey.stringValue) {
			self = value
		} else {
			return nil
		}
	}
	
	
	public var codingKey: any CodingKey {
		DictionaryCodingKey(stringValue: self.asString(.hex))
	}
	
	
}
