

extension Collection where Element == UInt8 {
	
	@inlinable
	public var asBytes : [UInt8] {
		[UInt8](self)
	}

	@inlinable
	public var asBinary : Binary {
		Binary(asBytes)
	}
	
	@inlinable
	public var asString : String {
		String(decoding: self, as: UTF8.self)
	}
	
}


extension Collection where Element == UInt16 {

	@inlinable
	public var asString : String {
		String(decoding: self, as: UTF16.self)
	}

}


extension Collection where Element == UnicodeScalar {

	@inlinable
	public var asString : String {
		String(String.UnicodeScalarView(self))
	}

}
