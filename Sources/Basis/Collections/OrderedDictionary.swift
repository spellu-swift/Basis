

/// 挿入順序が保持されたDictionary
public struct OrderedDictionary<Key, Value> where Key : Hashable {
	
	public typealias Element = (key: Key, value: Value)

	@usableFromInline
	internal var _elements: [Element]

	@inlinable
	public init(
	) {
		self._elements = []
	}
	
	@inlinable
	public init(
		_ elements: [(key: Key, value: Value)],
	) {
		self.init(elements, merge: .keepFirst)
	}
	
	@inlinable
	public init(
		_ elements: [(key: Key, value: Value)],
		merge: MergeMethod,
	) {
		self._elements = []

		switch merge {
			case .keepFirst:
				self.merge(elements) { first, _ in first }
			case .keepLast:
				self.merge(elements) { _, last in last }
		}
	}
	
	@inlinable
	public init(
		_ elements: [(key: Key, value: Value)],
		choice: (Value, Value) -> Value,
	) {
		self._elements = []
		self.merge(
			elements,
			choice: choice,
		)
	}

	@inlinable
	public init(
		_ elements: [(key: Key, value: Value?)],
	) {
		self.init(
			elements,
			merge: .keepFirst,
		)
	}
	
	@inlinable
	public init(
		_ elements: [(key: Key, value: Value?)],
		merge: MergeMethod,
	) {
		self.init(
			elements.compactMap{ k, v in v.map{(k, $0)} },
			merge: merge,
		)
	}
	
	@inlinable
	public init(
		_ elements: [(key: Key, value: Value?)],
		choice: (Value, Value) -> Value,
	) {
		self._elements = []
		self.merge(
			elements.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	@inlinable
	public init<S>(
		_ other: S,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value? {
		self.init(
			other,
			merge: .keepFirst,
		)
	}

	@inlinable
	public init<S>(
		_ other: S,
		merge: MergeMethod,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value? {
		self.init(
			other.compactMap{ k, v in v.map{(k, $0)} },
			merge: merge,
		)
	}
	
	@inlinable
	public init<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value? {
		self._elements = []
		self.merge(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	@inlinable
	public var elements: [(key: Key, value: Value)] {
		_elements
	}
	
	@inlinable
	public var isEmpty: Bool {
		_elements.count == 0
	}
	
	@inlinable
	public var isNotEmpty: Bool {
		_elements.count > 0
	}
	
	@inlinable
	public var count: Int {
		_elements.count
	}

	@inlinable
	public var keys: [Key] {
		_elements.map{ $0.key }
	}

	@inlinable
	public var values: [Value] {
		_elements.map{ $0.value }
	}
	
	@inlinable
	public var asDictionary: [Key : Value] {
		.init(_elements)
	}
	
	public subscript(
		key: Key,
	) -> Value? {
		@inlinable
		get {
			_elements.first{ $0.key == key }?.value
		}

		set {
			for index in _elements.indices {
				if _elements[index].key == key {
					if let newValue {
						_elements[index].value = newValue
					} else {
						_elements.remove(at: index)
					}
					return
				}
			}
			
			if let newValue {
				_elements.append((key, newValue))
			}
		}
	}
	
	@inlinable
	public func mapValues<T>(
		_ transform: (Value) throws -> T,
	) rethrows -> OrderedDictionary<Key, T> {
		try OrderedDictionary<Key, T>(
			_elements.map{ try ($0.key, transform($0.value)) }
		)
	}
		
	@inlinable
	public func compactMapValues<T>(
		_ transform: (Value) throws -> T?,
	) rethrows -> OrderedDictionary<Key, T> {
		try OrderedDictionary<Key, T>(
			_elements.compactMap {
				if let value = try transform($0.value) {
					return ($0.key, value)
				}
				else {
					return nil
				}
			}
		)
	}
		
	/// nil除去。
	@inlinable
	public func compacted<T>(
	) -> OrderedDictionary<Key, T> where Value == Optional<T> {
		compactMapValues{$0}
	}

}


extension OrderedDictionary : Map {
	
	/// Mapをマージ
	@inlinable
	public mutating func merge<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) where M : Map, M.Key == Key, M.Value == Value {
		for (key, value) in other {
			_merge(key: key, value: value, choice: choice)
		}
	}

	/// [(Key,Value)]をマージ
	@inlinable
	public mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Sequence, S.Element == (Key, Value) {
		for (key, value) in other {
			_merge(key: key, value: value, choice: choice)
		}
	}
	
	@usableFromInline
	mutating func _merge(
		key: Key,
		value right: Value,
		choice: (Value, Value) -> Value,
	) {
		if
			let left = self[key]
		{
			self[key] = choice(left, right)
		}
		else {
			self[key] = right
		}
	}
	
	public mutating func modifyAll(
		_ perform: (inout Value) throws-> Void
	) rethrows {
		for index in 0..<count {
			var element: Element = _elements[index]
			try perform(&element.value)
			_elements[index].value = element.value
		}
	}
	
	public mutating func modifyAll(
		_ perform: (Key, inout Value) throws -> Void
	) rethrows {
		for index in 0..<count {
			var element: Element = _elements[index]
			try perform(element.key, &element.value)
			_elements[index].value = element.value
		}
	}
	
	@discardableResult
	public mutating func remove(
		key: Key
	) -> Value? {
		for index in _elements.indices {
			let element = _elements[index]
			if element.key == key {
				_elements.remove(at: index)
				return element.value
			}
		}
		
		return nil
	}
	
	public mutating func removeAll(
		where shouldBeRemoved: (Key, Value) throws -> Bool
	) rethrows {
		for (key, value) in _elements {
			if try shouldBeRemoved(key, value) {
				self.remove(key: key)
			}
		}
	}
	
}


extension OrderedDictionary : Sendable where Element : Sendable {
}


extension OrderedDictionary : ExpressibleByDictionaryLiteral {

	public init(
		dictionaryLiteral elements: (Key, Value)...,
	) {
		self.init(elements)
	}

//	public init(
//		dictionaryLiteral elements: (Key, Value?)...,
//	) {
//		self.init(elements.compactMap{k, v in v.map{(k, $0)}})
//	}
	
}


extension OrderedDictionary : Equatable where Value: Equatable {

	public static func == (
		lhs: OrderedDictionary<Key, Value>,
		rhs: OrderedDictionary<Key, Value>,
	) -> Bool {
		guard lhs.count == rhs.count
		else { return false }
		
		for index in 0..<lhs.count {
			guard
				lhs._elements[index].key == rhs._elements[index].key,
				lhs._elements[index].value == rhs._elements[index].value
			else { return false }
		}
		
		return true
	}

}


extension OrderedDictionary : Hashable where Value : Hashable {

	@inlinable public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(count) // Discriminator

		for (key, value) in self {
			hasher.combine(key)
			hasher.combine(value)
		}
	}

}


extension OrderedDictionary : CustomStringConvertible {

	public var description: String {
		guard !isEmpty else { return "#D [:]" }

		let lines = _elements.map { key, value in
			let text = String(describing: value)
				.split(separator: "\n", omittingEmptySubsequences: false)
				.joined(separator: "\n  ")

			return "  \"\(key)\": \(text)"
		}

		return (["#D ["] + lines + ["]"]).joined(separator: "\n")
	}
}


extension OrderedDictionary where Key == String {
	
	public subscript(
		_ key: Substring,
	) -> Value? {
		self[key.asString]
	}

}
