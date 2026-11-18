

extension Dictionary {
	
	@inlinable
	public var asArray: [(Key, Value)] {
		Array(self)
	}
	
	/// nil除去。
	@inlinable
	public func compacted<T>(
	) -> [Key : T] where Value == Optional<T> {
		compactMapValues{$0}
	}
	
}


extension Dictionary {
	
	public mutating func modifyAll<E>(
		_ perform: (inout Value) throws(E) -> Void
	) throws(E) {
		for key in keys {
			var value: Value = self[key]!
			try perform(&value)
			self[key] = value
		}
	}
	
	public mutating func modifyAll<E>(
		_ perform: (Key, inout Value) throws(E) -> Void
	) throws(E) {
		for key in keys {
			var value: Value = self[key]!
			try perform(key, &value)
			self[key] = value
		}
	}

	@inlinable
	@discardableResult
	public mutating func remove(
		key: Key
	) -> Value? {
		removeValue(forKey: key)
	}
	
	public mutating func removeAll(
		where shouldBeRemoved: (Key, Value) throws -> Bool
	) rethrows {
		for (key, value) in self {
			if try shouldBeRemoved(key, value) {
				self.remove(key: key)
			}
		}
	}
	
}


