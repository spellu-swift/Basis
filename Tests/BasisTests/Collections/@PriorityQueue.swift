import Basis


/// 再現できる乱数（線形合同法）
private struct SeededGenerator : RandomNumberGenerator {
	var state: UInt64

	mutating func next() -> UInt64 {
		state = state &* 6364136223846793005 &+ 1442695040888963407
		return state
	}
}


/// 優先度で比べる値
private struct Job : Sendable, Comparable {
	let priority: Int
	let name: String

	static func < (
		lhs: Job,
		rhs: Job,
	) -> Bool {
		lhs.priority < rhs.priority
	}
}


@Suite struct PriorityQueueTests {

	/// 空になるまで取り出す。
	private func drain<Element>(
		_ queue: PriorityQueue<Element>,
	) -> [Element] {
		var queue: PriorityQueue<Element> = queue
		var result: [Element] = []

		while let element = queue.pop() {
			result.append(element)
		}

		return result
	}


	// MARK: - 作る


	@Test func 空で作る() {
		let queue: PriorityQueue<Int> = .init()

		#expect(queue.isEmpty)
		#expect(!queue.isNotEmpty)
		#expect(queue.count == 0)
		#expect(queue.first == nil)
	}


	@Test func 列から作る() {
		let queue: PriorityQueue<Int> = .init([5, 1, 4, 2, 3])

		#expect(queue.count == 5)
		#expect(queue.first == 1)
		#expect(drain(queue) == [1, 2, 3, 4, 5])
	}


	@Test func 要素が1つと2つの列から作る() {
		#expect(drain(PriorityQueue<Int>([7])) == [7])
		#expect(drain(PriorityQueue<Int>([2, 1])) == [1, 2])
	}


	// MARK: - 順序


	@Test func 引数なしで作ると小さい順に取り出す() {
		var queue: PriorityQueue<Int> = .init()

		queue.push(3)
		queue.push(1)
		queue.push(2)

		#expect(queue.first == 1)
		#expect(queue.pop() == 1)
		#expect(queue.pop() == 2)
		#expect(queue.pop() == 3)
		#expect(queue.pop() == nil)
	}


	@Test func descendingで作ると大きい順に取り出す() {
		var queue: PriorityQueue<Int> = .init([3, 1, 2], order: .descending)

		#expect(queue.order == .descending)
		#expect(queue.first == 3)
		#expect(queue.sorted == [3, 2, 1])
		#expect(queue.description == "[3, 2, 1]")

		queue.push(5)
		queue.push(0)
		#expect(drain(queue) == [5, 3, 2, 1, 0])
	}


	@Test func 既定はascending() {
		#expect(PriorityQueue<Int>().order == .ascending)
		#expect(PriorityQueue<Int>([1]).order == .ascending)
	}


	@Test func 優先度で比べる型を入れて使う() {
		var queue: PriorityQueue<Job> = .init()

		queue.push(.init(priority: 2, name: "b"))
		queue.push(.init(priority: 1, name: "a"))
		queue.push(.init(priority: 3, name: "c"))

		#expect(drain(queue).map(\.name) == ["a", "b", "c"])
	}


	@Test func 同じ値も重複して取り出す() {
		let queue: PriorityQueue<Int> = .init([2, 1, 2, 1, 2])

		#expect(drain(queue) == [1, 1, 2, 2, 2])
	}


	// MARK: - 出し入れ


	@Test func 取り出しと追加を交互にしても順序を保つ() {
		var queue: PriorityQueue<Int> = .init([5, 3, 8])

		#expect(queue.pop() == 3)
		queue.push(1)
		queue.push(9)
		#expect(queue.pop() == 1)
		#expect(queue.pop() == 5)
		queue.push(contentsOf: [4, 6])
		#expect(drain(queue) == [4, 6, 8, 9])
	}


	@Test func sortedは取り出す順でキューを変えない() {
		let queue: PriorityQueue<Int> = .init([3, 1, 2])

		#expect(queue.sorted == [1, 2, 3])
		#expect(queue.count == 3)
		#expect(queue.description == "[1, 2, 3]")
	}


	@Test func removeAllで空になる() {
		var queue: PriorityQueue<Int> = .init([3, 1, 2])
		queue.reserveCapacity(100)

		queue.removeAll(keepingCapacity: true)
		#expect(queue.isEmpty)

		queue.push(5)
		queue.removeAll()
		#expect(queue.isEmpty)
		#expect(queue.pop() == nil)
	}


	@Test func コピーは元に影響しない() {
		var original: PriorityQueue<Int> = .init([1, 2, 3])
		var copy: PriorityQueue<Int> = original

		copy.push(0)
		_ = original.pop()

		#expect(drain(original) == [2, 3])
		#expect(drain(copy) == [0, 1, 2, 3])
	}


	// MARK: - 整列との突き合わせ


	@Test func 無作為な操作で整列した配列と同じ順に取り出す() {
		var random: SeededGenerator = .init(state: 7)
		var queue: PriorityQueue<Int> = .init()
		var model: [Int] = []

		for _ in 0..<10_000 {
			if Int.random(in: 0..<3, using: &random) < 2 {
				let value: Int = .random(in: -1_000...1_000, using: &random)
				queue.push(value)
				model.append(value)
			}
			else {
				model.sort()
				#expect(queue.pop() == (model.isEmpty ? nil : model.removeFirst()))
			}

			#expect(queue.count == model.count)
		}

		#expect(drain(queue) == model.sorted())
	}

}
