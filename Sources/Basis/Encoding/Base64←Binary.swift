

extension Binary {
	
	
	@inlinable
	public var base64Binary: Binary {
		Binary(_raw.encodeBase64())
	}
	
	
	@inlinable
	public var base64String: String {
		self._raw.encodeBase64(options: [])
	}
	

	@inlinable
	public func encodeBase64(
		options: Base64.EncodingOptions = [],
		as: String.Type = String.self
	) -> String {
		self._raw.encodeBase64(options: options)
	}
	
	
	@inlinable
	public func encodeBase64(
		options: Base64.EncodingOptions = [],
		as: Binary.Type = Binary.self
	) -> Binary {
		Binary(_raw.encodeBase64(options: options))
	}
	
	
	@inlinable
	public func decodeBase64(
		options: Base64.DecodingOptions = [],
		as: String.Type = String.self
	) throws -> String {
		try _raw.decodeBase64(options: options)
	}
	
	
	@inlinable
	public func decodeBase64(
		options: Base64.DecodingOptions = [],
		as: Binary.Type = Binary.self
	) throws -> Binary {
		try Binary(_raw.decodeBase64(options: options))
	}
	
	
}


