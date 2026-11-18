

extension FilePath : Decodable {
	
	
	public init(
		from decoder: Decoder
	) throws {
		self._path = try String(from: decoder)
	}
	
	
}


extension FilePath : Encodable {
	
	
	public func encode(
		to encoder: Encoder
	) throws {
		try self._path.encode(to: encoder)
	}
	
	
}
