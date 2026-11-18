

extension Binary {
	
	
	public func encode(
		method: SerializationMethod,
		as type: String.Type = String.self
	) -> String {
		switch method {
			case .hex:
				return Hex.encode(asBytes)
			case .base64:
				return encodeBase64(options: [], as: String.self)
		}
	}
	
	
	public func encode(
		method: SerializationMethod,
		as type: Binary.Type = Binary.self
	) -> Binary {
		switch method {
			case .hex:
				return Hex.encode(asBytes).asBinary
			case .base64:
				return encodeBase64(options: [], as: Binary.self)
		}
	}
	
	
	public func decode(
		method: SerializationMethod,
		as type: String.Type = String.self
	) throws -> String {
		switch method {
			case .hex:
				return try Hex.decode(asString).asString
			case .base64:
				return try decodeBase64(options: [], as: String.self)
		}
	}
	
	
	public func decode(
		method: SerializationMethod,
		as type: Binary.Type = Binary.self
	) throws -> Binary {
		switch method {
			case .hex:
				return try Hex.decode(asString).asBinary
			case .base64:
				return try decodeBase64(options: [], as: Binary.self)
		}
	}
	
	
}
