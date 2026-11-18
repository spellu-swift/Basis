

public struct DictionaryKeyPath {
	
	
	var segments: [String]
	
	
	var isEmpty: Bool {
		return segments.isEmpty
	}
	
	
	var path: String {
		return segments.joined(separator: ".")
	}
	
	
	/// Strips off the first segment and returns a pair
	/// consisting of the first segment and the remaining key path.
	/// Returns nil if the key path has no segments.
	func headAndTail(
	) -> (head: String, tail: Self)? {
		guard isEmpty == false else { return nil }
		
		var tail = segments
		let head = tail.removeFirst()
		return (head, Self(segments: tail))
	}
	
	
}


extension DictionaryKeyPath {
	
	
	public init(
		_ string: String
	) {
		segments = string.split(separator: ".").asString
	}
	
	
}


extension DictionaryKeyPath: ExpressibleByStringLiteral {
	
	
	public init(
		stringLiteral value: String
	) {
		self.init(value)
	}
	
	
	public init(
		unicodeScalarLiteral value: String
	) {
		self.init(value)
	}
	
	
	public init(
		extendedGraphemeClusterLiteral value: String
	) {
		self.init(value)
	}
	
	
}


extension Dictionary where Key == String {
	
	
	public subscript(
		path keyPath: DictionaryKeyPath
	) -> Any? {
		get {
			switch keyPath.headAndTail() {
					// key path is empty.
				case nil:
					return nil
					
					// Reached the end of the key path.
				case let (key, remainingKeyPath)? where remainingKeyPath.isEmpty:
					return self[key]
					
					// Key path has a tail we need to traverse.
				case let (key, remainingKeyPath)?:
					switch self[key] {
						case let nestedDict as [Key : Any]:
							return nestedDict[path: remainingKeyPath]
							
						default:
							// Invalid keyPath
							return nil
					}
			}
		}
		
		set {
			switch keyPath.headAndTail() {
					// key path is empty.
				case nil:
					return
					
					// Reached the end of the key path.
				case let (key, remainingKeyPath)? where remainingKeyPath.isEmpty:
					self[key] = newValue as? Value
					
				case let (key, remainingKeyPath)?:
					let value = self[key]
					
					switch value {
						case var nestedDict as [Key : Any]:
							// Key path has a tail we need to traverse
							nestedDict[path: remainingKeyPath] = newValue
							self[key] = nestedDict as? Value
							
						default:
							// Invalid keyPath
							return
					}
			}
		}
	}
	
	
	public subscript(
		string keyPath: DictionaryKeyPath
	) -> String? {
		get { self[path: keyPath] as? String }
		set { self[path: keyPath] = newValue }
	}
	
	
	public subscript(
		int keyPath: DictionaryKeyPath
	) -> Int? {
		get { self[path: keyPath] as? Int }
		set { self[path: keyPath] = newValue }
	}
	
	
	public subscript(
		array keyPath: DictionaryKeyPath
	) -> [Any]? {
		get { self[path: keyPath] as? [Any] }
		set { self[path: keyPath] = newValue }
	}
	
	
	public subscript(
		dictioanry keyPath: DictionaryKeyPath
	) -> [String : Any]? {
		get { self[path: keyPath] as? [String : Any] }
		set { self[path: keyPath] = newValue }
	}
	
	
}

