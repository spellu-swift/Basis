

extension Binary {
	
	@inlinable
	public var hexString: String {
		Hex.encode(asBytes)
	}
	
}


extension String {
	
	@inlinable
	public func decodeHex(
	) throws -> Binary {
		try Hex.decode(self).asBinary
	}
	
}
