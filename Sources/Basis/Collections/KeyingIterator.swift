

@frozen
public struct KeyingIterator<Key, Value>: IteratorProtocol {

	public typealias Element = (key: Key, value: Value)

	@usableFromInline
	internal let _base: [Element]

	@usableFromInline
	internal var _position: Int

	@inlinable
	public init(_ base: [Element]) {
		self._base = base
		self._position = base.startIndex
	}

	@inlinable
	public mutating func next() -> Element? {
		guard _position < _base.endIndex else {
			return nil
		}
		let result = _base[_position]
		_position += 1
		return result
	}

}


