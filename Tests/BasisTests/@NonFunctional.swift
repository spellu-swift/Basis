import Basis


/// 再現できる乱数（線形合同法）
private struct SeededGenerator : RandomNumberGenerator {
	var state: UInt64

	mutating func next() -> UInt64 {
		state = state &* 6364136223846793005 &+ 1442695040888963407
		return state
	}
}


/// 非機能テスト。機能の正しさではなく、計算量などを確かめる。
/// 時間がかかるので、普段は実行しない。
@Suite(.enabled(
	if: POSIX.environment["BASIS_NONFUNCTIONAL_TESTS"] != nil,
	"BASIS_NONFUNCTIONAL_TESTSを指定して実行する",
))
struct NonFunctionalTests {

	@Test(.timeLimit(.minutes(1)))
	func Dequeの大量のFIFOの出し入れが要素数に比例する時間で終わる() {
		var deque: Deque<Int> = []
		var total: Int = 0

		// 要素数の2乗の時間がかかる実装では、終わらない
		for value in 0..<1_000_000 {
			deque.append(value)
		}

		while let value = deque.popFirst() {
			total &+= value
		}

		#expect(total == 499_999_500_000)
	}


	@Test(.timeLimit(.minutes(1)))
	func RingBufferに大量に入れても容量を超えて広がらない() {
		var buffer: RingBuffer<Int> = .init(capacity: 1_000)

		for value in 0..<1_000_000 {
			buffer.append(value)
		}

		#expect(buffer.count == 1_000)
		#expect(buffer.first == 999_000)
		#expect(buffer.last == 999_999)
	}


	@Test(.timeLimit(.minutes(1)))
	func PriorityQueueの大量の出し入れがn_log_nの時間で終わる() {
		var random: SeededGenerator = .init(state: 1)
		var queue: PriorityQueue<Int> = .init()

		for _ in 0..<200_000 {
			queue.push(.random(in: 0..<1_000_000, using: &random))
		}

		var previous: Int = .min
		var count: Int = 0

		while let value = queue.pop() {
			#expect(previous <= value)
			previous = value
			count += 1
		}

		#expect(count == 200_000)
	}

}
