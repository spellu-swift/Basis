

extension UnsafePointer where Pointee == CChar {
	
	@inlinable
	public var asString : String? {
		String(cString: self)
	}
	
}


extension Optional where Wrapped == UnsafePointer<CChar> {
	
	@inlinable
	public var asString : String? {
		self?.asString
	}
	
}
