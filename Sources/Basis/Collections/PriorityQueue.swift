/// 優先度付きキュー。中身は二分ヒープ。
///
/// 要素は`Comparable`であること。既定では、いちばん小さい要素から取り出す。
/// `order: .descending`で作ると、いちばん大きい要素から取り出す。
/// 優先度で並べたい値は、優先度で比べる`Comparable`の型にして入れる。
///
/// - 追加と取り出しはO(log n)。次に取り出す要素を見るのはO(1)。
/// - 等しい要素どうしの取り出し順は、入れた順とは限らない（安定ではない）。
///
/// ```swift
/// var queue: PriorityQueue<Int> = .init()
/// queue.push(3)
/// queue.push(1)
/// queue.push(2)
/// queue.pop()  // 1
/// ```
public struct PriorityQueue<Element> where Element : Comparable {

	/// 取り出す順番
	public enum Order : Sendable, Hashable {
		/// 小さい要素から
		case ascending
		/// 大きい要素から
		case descending
	}

	/// ヒープの順に並べた要素。先頭が次に取り出す要素。
	@usableFromInline
	var heap: [Element]

	/// 取り出す順番
	public let order: Order

	/// 空の優先度付きキューを作る。
	@inlinable
	public init(
		order: Order = .ascending,
	) {
		self.heap = []
		self.order = order
	}

	/// 列の要素を入れた優先度付きキューを作る。O(n)。
	@inlinable
	public init<S>(
		_ elements: S,
		order: Order = .ascending,
	) where S : Sequence, S.Element == Element {
		self.heap = Array(elements)
		self.order = order

		// 葉でない最後の節から根へ向かって、順に沈める
		if heap.count > 1 {
			for index in stride(from: heap.count / 2 - 1, through: 0, by: -1) {
				siftDown(from: index)
			}
		}
	}

}


// MARK: - Push / Pop


extension PriorityQueue {

	@inlinable
	public var count: Int {
		heap.count
	}

	@inlinable
	public var isEmpty: Bool {
		heap.isEmpty
	}

	@inlinable
	public var isNotEmpty: Bool {
		!heap.isEmpty
	}

	/// 次に取り出す要素。空ならnil。O(1)。
	@inlinable
	public var first: Element? {
		heap.first
	}

	/// 入れる。O(log n)。
	@inlinable
	public mutating func push(
		_ element: Element,
	) {
		heap.append(element)
		siftUp(from: heap.count - 1)
	}

	/// 列の要素を、順に入れる。
	@inlinable
	public mutating func push<S>(
		contentsOf elements: S,
	) where S : Sequence, S.Element == Element {
		for element in elements {
			push(element)
		}
	}

	/// 次の要素を取り出す。空ならnil。O(log n)。
	@inlinable
	public mutating func pop(
	) -> Element? {
		guard
			heap.isNotEmpty
		else { return nil }

		if heap.count == 1 {
			return heap.removeLast()
		}

		let first: Element = heap[0]
		heap[0] = heap.removeLast()
		siftDown(from: 0)
		return first
	}

	/// 少なくとも指定した数の要素を、広げずに入れられるようにする。
	@inlinable
	public mutating func reserveCapacity(
		_ minimumCapacity: Int,
	) {
		heap.reserveCapacity(minimumCapacity)
	}

	/// すべての要素を取り除く。
	@inlinable
	public mutating func removeAll(
		keepingCapacity keepCapacity: Bool = false,
	) {
		heap.removeAll(keepingCapacity: keepCapacity)
	}

	/// 取り出す順に並べた配列。O(n log n)。キューは変わらない。
	@inlinable
	public var sorted: [Element] {
		switch order {
			case .ascending:
				heap.sorted(by: <)
			case .descending:
				heap.sorted(by: >)
		}
	}

}


// MARK: - Heap


extension PriorityQueue {

	/// aがbより先に取り出されるべきか
	@inlinable
	func precedes(
		_ a: Element,
		_ b: Element,
	) -> Bool {
		switch order {
			case .ascending:
				a < b
			case .descending:
				b < a
		}
	}

	/// 親より先に来るあいだ、親と入れ替えて上げる。
	@inlinable
	mutating func siftUp(
		from start: Int,
	) {
		var child: Int = start

		while child > 0 {
			let parent: Int = (child - 1) / 2

			guard
				precedes(heap[child], heap[parent])
			else { break }

			heap.swapAt(child, parent)
			child = parent
		}
	}

	/// 子のほうが先に来るあいだ、先に来る子と入れ替えて下げる。
	@inlinable
	mutating func siftDown(
		from start: Int,
	) {
		var parent: Int = start

		while true {
			let left: Int = parent * 2 + 1
			let right: Int = left + 1
			var candidate: Int = parent

			if left < heap.count && precedes(heap[left], heap[candidate]) {
				candidate = left
			}

			if right < heap.count && precedes(heap[right], heap[candidate]) {
				candidate = right
			}

			if candidate == parent {
				return
			}

			heap.swapAt(parent, candidate)
			parent = candidate
		}
	}

}


// MARK: - Conformances


extension PriorityQueue : Sendable where Element : Sendable {}


extension PriorityQueue : CustomStringConvertible {

	/// 取り出す順に並べた要素
	public var description: String {
		sorted.description
	}

}
