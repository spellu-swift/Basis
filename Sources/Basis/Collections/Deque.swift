/// 両端キュー。前後どちらにも、償却O(1)で出し入れできる。
///
/// 中身は、容量を2倍ずつ広げるリングバッファ。
/// 添字による読み書きもO(1)でできる。添字は、先頭を0とする位置。
///
/// - FIFO（待ち行列）：`append(_:)`で入れ、`popFirst()`で取り出す。
/// - LIFO（スタック）：`append(_:)`で入れ、`popLast()`で取り出す。
///
/// ```swift
/// var pending: Deque<Int> = [1, 2]
/// pending.append(3)
/// pending.prepend(0)
/// pending.popFirst()  // 0
/// pending.popLast()   // 3
/// ```
public struct Deque<Element> {

	/// 要素の置き場。使っていない場所はnil。
	@usableFromInline
	var storage: [Element?]

	/// 先頭の要素の、storageでの位置
	@usableFromInline
	var head: Int

	@usableFromInline
	var _count: Int

	/// 空の両端キューを作る。
	@inlinable
	public init(
	) {
		self.storage = []
		self.head = 0
		self._count = 0
	}

	/// 少なくとも指定した数の要素を、広げずに入れられる両端キューを作る。
	@inlinable
	public init(
		minimumCapacity: Int,
	) {
		precondition(minimumCapacity >= 0, "Negative capacity")

		self.storage = .init(repeating: nil, count: minimumCapacity)
		self.head = 0
		self._count = 0
	}

	/// 列の要素を、順に並べた両端キューを作る。
	@inlinable
	public init<S>(
		_ elements: S,
	) where S : Sequence, S.Element == Element {
		self.storage = elements.map { Optional($0) }
		self.head = 0
		self._count = storage.count
	}

}


// MARK: - Capacity


extension Deque {

	/// 広げずに入れられる要素の数
	@inlinable
	public var capacity: Int {
		storage.count
	}

	@inlinable
	public var isNotEmpty: Bool {
		_count > 0
	}

	/// 少なくとも指定した数の要素を、広げずに入れられるようにする。
	@inlinable
	public mutating func reserveCapacity(
		_ minimumCapacity: Int,
	) {
		if minimumCapacity > storage.count {
			resize(to: minimumCapacity)
		}
	}

	/// 先頭からの位置を、storageでの位置に直す。
	@inlinable
	func slot(
		_ offset: Int,
	) -> Int {
		let index: Int
		= head + offset

		return index < storage.count ? index : index - storage.count
	}

	/// 満杯なら広げる。
	@inlinable
	mutating func growIfFull(
	) {
		if _count == storage.count {
			resize(to: Swift.max(16, storage.count * 2))
		}
	}

	/// 容量を変え、要素を先頭から詰めて並べ直す。
	@usableFromInline
	mutating func resize(
		to newCapacity: Int,
	) {
		var expanded: [Element?]
		= .init(repeating: nil, count: newCapacity)

		for offset in 0..<_count {
			expanded[offset] = storage[slot(offset)]
		}

		storage = expanded
		head = 0
	}

}


// MARK: - Push / Pop


extension Deque {

	/// 末尾に入れる。償却O(1)。
	@inlinable
	public mutating func append(
		_ element: Element,
	) {
		growIfFull()
		storage[slot(_count)] = element
		_count += 1
	}

	/// 列の要素を、順に末尾に入れる。
	@inlinable
	public mutating func append<S>(
		contentsOf elements: S,
	) where S : Sequence, S.Element == Element {
		for element in elements {
			append(element)
		}
	}

	/// 先頭に入れる。償却O(1)。
	@inlinable
	public mutating func prepend(
		_ element: Element,
	) {
		growIfFull()
		head = head == 0 ? storage.count - 1 : head - 1
		storage[head] = element
		_count += 1
	}

	/// 先頭を取り出す。空ならnil。O(1)。
	@inlinable
	public mutating func popFirst(
	) -> Element? {
		guard
			_count > 0
		else { return nil }

		let element: Element? = storage[head]
		storage[head] = nil
		head = slot(1)
		_count -= 1

		if _count == 0 {
			head = 0
		}

		return element
	}

	/// 末尾を取り出す。空ならnil。O(1)。
	@inlinable
	public mutating func popLast(
	) -> Element? {
		guard
			_count > 0
		else { return nil }

		let index: Int = slot(_count - 1)
		let element: Element? = storage[index]
		storage[index] = nil
		_count -= 1

		if _count == 0 {
			head = 0
		}

		return element
	}

	/// 先頭を取り出す。空であってはならない。O(1)。
	@inlinable
	@discardableResult
	public mutating func removeFirst(
	) -> Element {
		guard
			let element = popFirst()
		else {
			preconditionFailure("Can't remove first element from an empty Deque")
		}

		return element
	}

	/// 末尾を取り出す。空であってはならない。O(1)。
	@inlinable
	@discardableResult
	public mutating func removeLast(
	) -> Element {
		guard
			let element = popLast()
		else {
			preconditionFailure("Can't remove last element from an empty Deque")
		}

		return element
	}

	/// すべての要素を取り除く。
	@inlinable
	public mutating func removeAll(
		keepingCapacity keepCapacity: Bool = false,
	) {
		if keepCapacity {
			for offset in 0..<_count {
				storage[slot(offset)] = nil
			}
		}
		else {
			storage = []
		}

		head = 0
		_count = 0
	}

}


// MARK: - Collection


extension Deque : RandomAccessCollection, MutableCollection {

	public typealias Index = Int

	@inlinable
	public var startIndex: Int {
		0
	}

	@inlinable
	public var endIndex: Int {
		_count
	}

	@inlinable
	public var count: Int {
		_count
	}

	@inlinable
	public var isEmpty: Bool {
		_count == 0
	}

	/// 先頭からの位置の要素。O(1)。
	@inlinable
	public subscript(
		position: Int,
	) -> Element {
		get {
			precondition(indices.contains(position), "Index out of range")
			return storage[slot(position)]!
		}
		set {
			precondition(indices.contains(position), "Index out of range")
			storage[slot(position)] = newValue
		}
	}

}


// MARK: - Conformances


extension Deque : ExpressibleByArrayLiteral {

	@inlinable
	public init(
		arrayLiteral elements: Element...,
	) {
		self.init(elements)
	}

}


extension Deque : Equatable where Element : Equatable {

	@inlinable
	public static func == (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		lhs.elementsEqual(rhs)
	}

}


extension Deque : Hashable where Element : Hashable {

	@inlinable
	public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(_count)

		for element in self {
			hasher.combine(element)
		}
	}

}


extension Deque : Sendable where Element : Sendable {}


extension Deque : CustomStringConvertible {

	public var description: String {
		Array(self).description
	}

}
