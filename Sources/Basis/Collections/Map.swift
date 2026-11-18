

/// Swift.Dictionary と Basis.OrderedDictionary の共通インターフェース
public protocol Map<Key, Value> : Sequence where Element == (key: Key, value: Value) {

	associatedtype Key
	associatedtype Value

	init(
		_ elements: [(key: Key, value: Value)],
	)
	
	init(
		_ elements: [(key: Key, value: Value)],
		merge: MergeMethod,
	)

	init(
		_ elements: [(key: Key, value: Value)],
		choice: (Value, Value) -> Value,
	)

	init(
		_ elements: [(key: Key, value: Value?)],
	)
	
	init(
		_ elements: [(key: Key, value: Value?)],
		merge: MergeMethod,
	)

	init(
		_ elements: [(key: Key, value: Value?)],
		choice: (Value, Value) -> Value,
	)

	init<S>(
		_ other: S,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value?

	init<S>(
		_ other: S,
		merge: MergeMethod,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value?

	init<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Map, S.Key == Self.Key, S.Value == Self.Value?

	var elements: [(key: Key, value: Value)] { get }
	
	var isEmpty: Bool { get }

	var isNotEmpty: Bool { get }

	func exists(
		key: Key
	) -> Bool
	
	func notExists(
		key: Key
	) -> Bool
	
	subscript(
		key: Key
	) -> Value?
	{ get set }
	
	func get(
		key: Key
	) -> Value?
	
	mutating func insert(
		key: Key,
		value: Value
	) -> Value

	mutating func insertIfEmpty(
		key: Key,
		value: Value
	) -> Value
	
	mutating func insertIfEmpty(
		key: Key,
		value provider: () throws -> Value
	) rethrows -> Value

	mutating func modify(
		key: Key,
		perform: (inout Value) -> Void
	) -> Value?
	
	mutating func modify(
		key: Key,
		perform: (Key, inout Value) -> Void
	) -> Value?

	mutating func modify(
		key: Key,
		`default` defaultValue: Value,
		perform: (inout Value) -> Void
	) -> Value
	
	mutating func modify(
		key: Key,
		`default` defaultValue: Value,
		perform: (Key, inout Value) -> Void
	) -> Value

	mutating func modifyOrInsert(
		key: Key,
		`default`: Value,
		perform: (inout Value) -> Void
	) -> Value
	
	mutating func modifyOrInsert(
		key: Key,
		`default`: Value,
		perform: (Key, inout Value) -> Void
	) -> Value
	
	mutating func modifyOrInsert(
		key: Key,
		perform: (inout Value) -> Void,
		`default`: () -> Value
	) -> Value
	
	mutating func modifyOrInsert(
		key: Key,
		perform: (Key, inout Value) -> Void,
		`default`: () -> Value
	) -> Value

	mutating func modifyAll(
		_ perform: (inout Value) throws -> Void
	) rethrows
	
	mutating func modifyAll(
		_ perform: (Key, inout Value) throws -> Void
	) rethrows
	
	mutating func merge<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) where M : Map, M.Key == Key, M.Value == Value
	
	func merging<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) -> Self where M : Map, M.Key == Key, M.Value == Value

	mutating func merge<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) where M : Map, M.Key == Key, M.Value == Value?
	
	func merging<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) -> Self where M : Map, M.Key == Key, M.Value == Value?
	
	mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Sequence, S.Element == (Key, Value)
	
	func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Sequence, S.Element == (Key, Value)

	mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Sequence, S.Element == (Key, Value?)
	
	func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Sequence, S.Element == (Key, Value?)
	
	mutating func remove(
		key: Key
	) -> Value?
		
	mutating func removeAll(
		where shouldBeRemoved: (Key, Value) throws -> Bool
	) rethrows
	
	mutating func clear()
	
}




// Swift#Dictionary: [], []/insert, remove, update
// Rust#HashMap: get, insert, remove, modify
// Java#HashMap: get, put, remove, replace/compute
extension Map {

	public func exists(
		key: Key
	) -> Bool {
		self[key] != nil
	}

	public func notExists(
		key: Key
	) -> Bool {
		self[key] == nil
	}
	
	public func get(
		key: Key
	) -> Value? {
		self[key]
	}
	
	@discardableResult
	public mutating func insert(
		key: Key,
		value: Value
	) -> Value {
		self[key] = value
		return value
	}
	
	@inlinable
	@discardableResult
	public mutating func insertIfEmpty(
		key: Key,
		value: Value
	) -> Value {
		self.insertIfEmpty(key: key, value: {value})
	}
	
	
	@discardableResult
	public mutating func insertIfEmpty(
		key: Key,
		value provider: () throws -> Value
	) rethrows -> Value {
		if
			let value = self[key]
		{
			return value
		}
		else {
			let value = try provider()
			self[key] = value
			return value
		}
	}
	
	@discardableResult
	public mutating func modify(
		key: Key,
		perform: (inout Value) -> Void
	) -> Value? {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(&newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				return nil
		}
	}
	
	@discardableResult
	public mutating func modify(
		key: Key,
		perform: (Key, inout Value) -> Void
	) -> Value? {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(key, &newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				return nil
		}
	}
	
	@discardableResult
	public mutating func modify(
		key: Key,
		`default` defaultValue: Value,
		perform: (inout Value) -> Void
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(&newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				var newValue = defaultValue
				perform(&newValue)
				self[key] = newValue
				return newValue
		}
	}
	
	@discardableResult
	public mutating func modify(
		key: Key,
		`default` defaultValue: Value,
		perform: (Key, inout Value) -> Void
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(key, &newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				var newValue = defaultValue
				perform(key, &newValue)
				self[key] = newValue
				return newValue
		}
	}
	
	@discardableResult
	public mutating func modifyOrInsert(
		key: Key,
		`default` defaultValue: Value,
		perform: (inout Value) -> Void
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(&newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				self[key] = defaultValue
				return defaultValue
		}
	}
	
	@discardableResult
	public mutating func modifyOrInsert(
		key: Key,
		`default` defaultValue: Value,
		perform: (Key, inout Value) -> Void
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(key, &newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				self[key] = defaultValue
				return defaultValue
		}
	}
	
	@discardableResult
	public mutating func modifyOrInsert(
		key: Key,
		perform: (inout Value) -> Void,
		`default`: () -> Value
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(&newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				let newValue = `default`()
				self[key] = newValue
				return newValue
		}
	}
	
	@discardableResult
	public mutating func modifyOrInsert(
		key: Key,
		perform: (Key, inout Value) -> Void,
		`default`: () -> Value
	) -> Value {
		switch self[key] {
			case .some(let value):
				var newValue = value
				perform(key, &newValue)
				self[key] = newValue
				return newValue
				
			case .none:
				let newValue = `default`()
				self[key] = newValue
				return newValue
		}
	}
	
	public func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Map, S.Key == Key, S.Value == Value {
		var map = self
		map.merge(other, choice: choice)
		return map
	}

	public func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Sequence, S.Element == (Key, Value) {
		var map = self
		map.merge(other, choice: choice)
		return map
	}
	
	/// マージ、("Key" : nil)を許容する。
	public mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Map, S.Key == Key, S.Value == Value? {
		merge(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	/// マージ、("Key" : nil)を許容する。
	public func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Map, S.Key == Key, S.Value == Value? {
		merging(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	/// マージ、("Key" : nil)を許容する。
	@inlinable
	public mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Sequence, S.Element == (Key, Value?) {
		merge(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	/// マージ、("Key" : nil)を許容する。
	@inlinable
	public func merging<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) -> Self where S : Sequence, S.Element == (Key, Value?) {
		merging(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}
	
	public mutating func clear(
	) {
		removeAll{ _, _ in true }
	}
	
}


