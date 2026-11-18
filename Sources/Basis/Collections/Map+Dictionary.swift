

extension Dictionary : Map {

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
		switch merge {
			case .keepFirst:
				self.init(elements) { first, _ in first }
			case .keepLast:
				self.init(elements) { _, last in last }
		}
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
		_ elements: [(key: Key, value: Value)],
		choice: (Value, Value) -> Value,
	) {
		self.init(
			elements,
			uniquingKeysWith: choice,
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
		self.init(
			elements.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	@inlinable
	public init<M>(
		_ other: M,
	) where M : Map, M.Key == Key, M.Value == Value? {
		self.init(
			other,
			merge: .keepFirst,
		)
	}
	
	@inlinable
	public init<M>(
		_ other: M,
		merge: MergeMethod,
	) where M : Map, M.Key == Key, M.Value == Value? {
		self.init(
			other.compactMap{ k, v in v.map{(k, $0)} },
			merge: merge,
		)
	}

	@inlinable
	public init<M>(
		_ other: M,
		choice: (Value, Value) -> Value,
	) where M : Map, M.Key == Key, M.Value == Value? {
		self.init(
			other.compactMap{ k, v in v.map{(k, $0)} },
			choice: choice,
		)
	}

	@inlinable
	public var elements: [(key: Key, value: Value)] {
		Array(self)
	}
	
	public mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Map, S.Key == Key, S.Value == Value {
		merge(other.map{($0, $1)}, uniquingKeysWith: choice)
	}

	public mutating func merge<S>(
		_ other: S,
		choice: (Value, Value) -> Value,
	) where S : Sequence, S.Element == (Key, Value) {
		merge(other, uniquingKeysWith: choice)
	}
	
}


