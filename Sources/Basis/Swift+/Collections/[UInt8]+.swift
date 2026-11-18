

extension Array where Element == UInt8 {
	
	@inlinable
	public var asBinary: Binary {
		Binary(self)
	}
	
	@inlinable
	public var asString: String {
		String(decoding: self, as: UTF8.self)
	}
	
}


extension ArraySlice where Element == UInt8 {
	
	@inlinable
	public var asBytes: [UInt8] {
		[UInt8](self)
	}
	
	@inlinable
	public var asBinary: Binary {
		Binary([UInt8](self))
	}
	
	@inlinable
	public var asString: String {
		String(decoding: self, as: UTF8.self)
	}
	
}


