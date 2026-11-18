/// 容量を固定したリングバッファ。
///
/// 容量は作るときに決め、広げない。
/// 満杯のときに末尾に入れると、いちばん古い（先頭の）要素を捨てる。
/// ログの最後のN件や、履歴などに使う。
///
/// 添字は、いちばん古い要素を0とする位置。
///
/// ```swift
/// var recent: RingBuffer<Int> = .init(capacity: 3)
/// recent.append(1)
/// recent.append(2)
/// recent.append(3)
/// recent.append(4)  // 1を捨てる
/// Array(recent)     // [2, 3, 4]
/// ```
public struct RingBuffer<Element> {

	@usableFromInline
	var elements: Deque<Element>

	/// 入れられる要素の数。作った後は変わらない。
	public let capacity: Int

	/// 空のリングバッファを作る。容量は1以上。
	@inlinable
	public init(
		capacity: Int,
	) {
		precondition(capacity > 0, "RingBuffer capacity must be positive")

		self.elements = .init(minimumCapacity: capacity)
		self.capacity = capacity
	}

	/// 列の要素を順に入れたリングバッファを作る。
	/// 容量より多ければ、後ろの容量分だけが残る。
	@inlinable
	public init<S>(
		capacity: Int,
		_ elements: S,
	) where S : Sequence, S.Element == Element {
		self.init(capacity: capacity)
		append(contentsOf: elements)
	}

}


// MARK: - Push / Pop


extension RingBuffer {

	/// 満杯か
	@inlinable
	public var isFull: Bool {
		elements.count == capacity
	}

	@inlinable
	public var isNotEmpty: Bool {
		elements.isNotEmpty
	}

	/// 末尾に入れる。O(1)。
	///
	/// 満杯なら、いちばん古い要素を捨てて、その要素を返す。満杯でなければnil。
	@inlinable
	@discardableResult
	public mutating func append(
		_ element: Element,
	) -> Element? {
		let dropped: Element?
		= isFull ? elements.popFirst() : nil

		elements.append(element)
		return dropped
	}

	/// 列の要素を、順に末尾に入れる。
	@inlinable
	public mutating func append<S>(
		contentsOf newElements: S,
	) where S : Sequence, S.Element == Element {
		for element in newElements {
			append(element)
		}
	}

	/// いちばん古い要素を取り出す。空ならnil。O(1)。
	@inlinable
	public mutating func popFirst(
	) -> Element? {
		elements.popFirst()
	}

	/// いちばん新しい要素を取り出す。空ならnil。O(1)。
	@inlinable
	public mutating func popLast(
	) -> Element? {
		elements.popLast()
	}

	/// すべての要素を取り除く。容量は変わらない。
	@inlinable
	public mutating func removeAll(
	) {
		elements.removeAll(keepingCapacity: true)
	}

}


// MARK: - Collection


extension RingBuffer : RandomAccessCollection, MutableCollection {

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
	public var count: Int {
		elements.count
	}

	@inlinable
	public var isEmpty: Bool {
		elements.isEmpty
	}

	/// いちばん古い要素を0とする位置の要素。O(1)。
	@inlinable
	public subscript(
		position: Int,
	) -> Element {
		get {
			elements[position]
		}
		set {
			elements[position] = newValue
		}
	}

}


// MARK: - Conformances


extension RingBuffer : Equatable where Element : Equatable {

	/// 容量と要素が同じなら等しい。
	@inlinable
	public static func == (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		lhs.capacity == rhs.capacity && lhs.elements == rhs.elements
	}

}


extension RingBuffer : Hashable where Element : Hashable {

	@inlinable
	public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(capacity)
		hasher.combine(elements)
	}

}


extension RingBuffer : Sendable where Element : Sendable {}


extension RingBuffer : CustomStringConvertible {

	public var description: String {
		Array(self).description
	}

}
