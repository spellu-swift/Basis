

extension UnsafeMutablePointer where Pointee == CChar {
	
	@inlinable
	public var asString : String? {
		String(cString: self)
	}
	
}


extension Optional where Wrapped == UnsafeMutablePointer<CChar> {
	
	@inlinable
	public var asString : String? {
		switch self {
			case .none:
				return nil
				
			case .some(let value):
				return value.asString
		}
	}

}
