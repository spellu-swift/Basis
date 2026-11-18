

extension Binary : Decodable {
	
	
	public init(
		from decoder: Decoder
	) throws {
		//		if
		//			let decoder: SingleValueDecodingContainer = decoder as? SingleValueDecodingContainer
		//		{
		//			let base64String: String = try decoder.decode(String.self)
		//
		//			try self.init(base64: base64String)
		//		}
		//		else {
		//			self.init(try [UInt8](from: decoder))
		//		}
		
		self._raw = try [UInt8](from: decoder)
	}
	
	
}


extension Binary : Encodable {
	
	
	public func encode(
		to encoder: Encoder
	) throws {
		//		try base64String.encode(to: encoder)
		
		try self._raw.encode(to: encoder)
	}
	
	
}
