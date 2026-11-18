

extension OrderedDictionary : Sequence {

	@frozen
	public struct Iterator: IteratorProtocol {
		@usableFromInline
		internal let _base: OrderedDictionary
		
		@usableFromInline
		internal var _position: Int
		
		@inlinable
		@inline(__always)
		internal init(
			_base: OrderedDictionary,
		) {
			self._base = _base
			self._position = 0
		}
		
		@inlinable
		public mutating func next(
		) -> Element? {
			guard _position < _base.count else { return nil }
			let result = _base.elements[_position]
			_position += 1
			return result
		}
	}

	@inlinable
	@inline(__always)
	public var underestimatedCount: Int {
		count
	}

	@inlinable
	@inline(__always)
	public func makeIterator() -> Iterator {
		Iterator(_base: self)
	}

}


extension OrderedDictionary : RandomAccessCollection {

	public typealias Index = Int

	@inlinable
	public var startIndex: Int {
		0
	}

	@inlinable
	public var endIndex: Int {
		elements.count
	}

	@inlinable
	public func index(
		after i: Int,
	) -> Int {
		i + 1
	}

	@inlinable
	public func index(
		before i: Int,
	) -> Int { i - 1 }

	@inlinable
	public subscript(
		position: Int,
	) -> Element {
		elements[position]
	}

}


