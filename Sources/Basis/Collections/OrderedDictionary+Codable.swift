

extension OrderedDictionary : Codable where Key : CodingKeyRepresentable, Value : Codable {
		
	public init(
		from decoder: Decoder
	) throws {
		let container = try decoder.container(keyedBy: DictionaryCodingKey.self)
		
		let elements = try container.allKeys.map { codingKey in
			guard
				let key: Key = Key(codingKey: codingKey)
			else {
				throw DecodingError.dataCorruptedError(
					forKey: codingKey,
					in: container,
					debugDescription: "Could not convert key to type \(Key.self)"
				)
			}

			return try (key, container.decode(Value.self, forKey: codingKey))
		}

		guard Set(elements.map { $0.0 }).count == elements.count
		else {
			throw DecodingError.dataCorrupted(.init(
				codingPath: decoder.codingPath,
				debugDescription: "Duplicate keys in OrderedDictionary",
			))
		}

		self.init(elements)
	}
		
	public func encode(
		to encoder: Encoder
	) throws {
		var container = encoder.container(
			keyedBy: DictionaryCodingKey.self,
		)
		
		for (key, value) in elements {
			let codingKey = key.codingKey

			let dictionaryCodingKey = DictionaryCodingKey(codingKey: codingKey)

			try container.encode(value, forKey: dictionaryCodingKey)
		}
	}
		
}


