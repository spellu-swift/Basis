import Basis


/// 再現できる乱数（線形合同法）
private struct SeededGenerator : RandomNumberGenerator {
	var state: UInt64

	mutating func next() -> UInt64 {
		state = state &* 6364136223846793005 &+ 1442695040888963407
		return state
	}
}


@Suite struct DequeTests {

	// MARK: - 作る


	@Test func 空で作る() {
		let deque: Deque<Int> = .init()

		#expect(deque.isEmpty)
		#expect(!deque.isNotEmpty)
		#expect(deque.count == 0)
		#expect(deque.capacity == 0)
		#expect(deque.first == nil)
		#expect(deque.last == nil)
	}


	@Test func 容量を指定して作る() {
		let deque: Deque<Int> = .init(minimumCapacity: 10)

		#expect(deque.isEmpty)
		#expect(deque.capacity == 10)
	}


	@Test func 列と配列リテラルから作る() {
		let fromSequence: Deque<Int> = .init(1...3)
		let fromLiteral: Deque<Int> = [1, 2, 3]

		#expect(Array(fromSequence) == [1, 2, 3])
		#expect(fromSequence == fromLiteral)
		#expect(fromLiteral.first == 1)
		#expect(fromLiteral.last == 3)
	}


	// MARK: - 出し入れ


	@Test func FIFOとして使う() {
		var deque: Deque<Int> = []

		for value in 1...5 {
			deque.append(value)
		}

		#expect(deque.popFirst() == 1)
		#expect(deque.popFirst() == 2)
		deque.append(6)
		#expect(Array(deque) == [3, 4, 5, 6])
	}


	@Test func LIFOとして使う() {
		var deque: Deque<Int> = [1, 2, 3]

		#expect(deque.popLast() == 3)
		deque.append(4)
		#expect(deque.popLast() == 4)
		#expect(deque.popLast() == 2)
		#expect(Array(deque) == [1])
	}


	@Test func 前に入れる() {
		var deque: Deque<Int> = [2, 3]

		deque.prepend(1)
		deque.prepend(0)

		#expect(Array(deque) == [0, 1, 2, 3])
		#expect(deque.popFirst() == 0)
		#expect(deque.popLast() == 3)
	}


	@Test func 空から取り出すとnil() {
		var deque: Deque<Int> = []

		#expect(deque.popFirst() == nil)
		#expect(deque.popLast() == nil)

		deque.append(1)
		#expect(deque.popFirst() == 1)
		#expect(deque.popFirst() == nil)
		#expect(deque.popLast() == nil)
	}


	@Test func removeFirstとremoveLastは要素を返す() {
		var deque: Deque<Int> = [1, 2, 3]

		#expect(deque.removeFirst() == 1)
		#expect(deque.removeLast() == 3)
		#expect(Array(deque) == [2])
	}


	@Test func 列の要素を末尾に入れる() {
		var deque: Deque<Int> = [1]

		deque.append(contentsOf: [2, 3])
		deque.append(contentsOf: 4...5)

		#expect(Array(deque) == [1, 2, 3, 4, 5])
	}


	// MARK: - 輪をまたぐ


	@Test func 輪をまたいでも順番を保つ() {
		var deque: Deque<Int> = .init(minimumCapacity: 4)

		// 先頭を進めてから、末尾を輪の始めに回す
		deque.append(contentsOf: [1, 2, 3, 4])
		#expect(deque.popFirst() == 1)
		#expect(deque.popFirst() == 2)
		deque.append(5)
		deque.append(6)

		#expect(deque.capacity == 4)
		#expect(Array(deque) == [3, 4, 5, 6])
		#expect(deque[0] == 3)
		#expect(deque[3] == 6)
	}


	@Test func 輪をまたいだ状態で広げても順番を保つ() {
		var deque: Deque<Int> = .init(minimumCapacity: 4)

		deque.append(contentsOf: [1, 2, 3, 4])
		_ = deque.popFirst()
		_ = deque.popFirst()
		deque.append(contentsOf: [5, 6])
		// 満杯の状態から、さらに入れる
		deque.append(7)
		deque.prepend(2)

		#expect(deque.capacity >= 6)
		#expect(Array(deque) == [2, 3, 4, 5, 6, 7])
	}


	@Test func 空のときに前に入れると輪の最後に置く() {
		var deque: Deque<Int> = .init(minimumCapacity: 4)

		deque.prepend(1)
		deque.append(2)
		deque.prepend(0)

		#expect(Array(deque) == [0, 1, 2])
		#expect(deque.capacity == 4)
	}


	// MARK: - 添字


	@Test func 添字で読み書きする() {
		var deque: Deque<String> = ["a", "b", "c"]

		deque[1] = "B"
		deque.prepend("z")

		#expect(deque[0] == "z")
		#expect(deque[2] == "B")
		#expect(deque.startIndex == 0)
		#expect(deque.endIndex == 4)
		#expect(Array(deque.reversed()) == ["c", "B", "a", "z"])
	}


	// MARK: - 容量と削除


	@Test func reserveCapacityは小さくしない() {
		var deque: Deque<Int> = [1, 2, 3]

		deque.reserveCapacity(100)
		#expect(deque.capacity == 100)
		#expect(Array(deque) == [1, 2, 3])

		deque.reserveCapacity(10)
		#expect(deque.capacity == 100)
	}


	@Test func removeAllは容量を残すか選べる() {
		var deque: Deque<Int> = .init(minimumCapacity: 8)
		deque.append(contentsOf: 1...5)

		deque.removeAll(keepingCapacity: true)
		#expect(deque.isEmpty)
		#expect(deque.capacity == 8)

		deque.append(1)
		deque.removeAll()
		#expect(deque.isEmpty)
		#expect(deque.capacity == 0)
	}


	// MARK: - 値の意味


	@Test func コピーは元に影響しない() {
		var original: Deque<Int> = [1, 2, 3]
		var copy: Deque<Int> = original

		copy.append(4)
		_ = original.popFirst()

		#expect(Array(original) == [2, 3])
		#expect(Array(copy) == [1, 2, 3, 4])
	}


	@Test func 中の配置が違っても要素が同じなら等しい() {
		var shifted: Deque<Int> = .init(minimumCapacity: 4)
		shifted.append(contentsOf: [0, 0, 1, 2])
		_ = shifted.popFirst()
		_ = shifted.popFirst()
		shifted.append(3)

		let plain: Deque<Int> = [1, 2, 3]

		#expect(shifted == plain)
		#expect(shifted.hashValue == plain.hashValue)
		#expect(shifted != [1, 2])
	}


	@Test func descriptionは配列と同じ() {
		let deque: Deque<Int> = [1, 2, 3]

		#expect(deque.description == "[1, 2, 3]")
		#expect(Deque<Int>().description == "[]")
	}


	@Test func 取り出した要素は解放される() {
		final class Box {}

		weak var weakBox: Box?
		var deque: Deque<Box> = []

		do {
			let box: Box = .init()
			weakBox = box
			deque.append(box)
		}

		#expect(weakBox != nil)
		_ = deque.popFirst()
		#expect(weakBox == nil)
	}


	// MARK: - 配列との突き合わせ


	@Test func 無作為な操作で配列と同じ結果になる() {
		var random: SeededGenerator = .init(state: 42)
		var deque: Deque<Int> = []
		var model: [Int] = []

		for step in 0..<10_000 {
			switch Int.random(in: 0..<6, using: &random) {
				case 0, 1:
					deque.append(step)
					model.append(step)
				case 2:
					deque.prepend(step)
					model.insert(step, at: 0)
				case 3:
					#expect(deque.popFirst() == (model.isEmpty ? nil : model.removeFirst()))
				case 4:
					#expect(deque.popLast() == model.popLast())
				default:
					if model.isNotEmpty {
						let index: Int = .random(in: 0..<model.count, using: &random)
						deque[index] = -step
						model[index] = -step
					}
			}

			#expect(deque.count == model.count)
		}

		#expect(Array(deque) == model)
	}

}
