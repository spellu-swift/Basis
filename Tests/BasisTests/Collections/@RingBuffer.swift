import Basis


@Suite struct RingBufferTests {

	// MARK: - 作る


	@Test func 空で作る() {
		let buffer: RingBuffer<Int> = .init(capacity: 3)

		#expect(buffer.capacity == 3)
		#expect(buffer.isEmpty)
		#expect(!buffer.isNotEmpty)
		#expect(!buffer.isFull)
		#expect(buffer.count == 0)
	}


	@Test func 列から作ると後ろの容量分だけ残る() {
		let short: RingBuffer<Int> = .init(capacity: 5, [1, 2])
		let long: RingBuffer<Int> = .init(capacity: 3, 1...6)

		#expect(Array(short) == [1, 2])
		#expect(Array(long) == [4, 5, 6])
		#expect(long.isFull)
	}


	// MARK: - 出し入れ


	@Test func 満杯になるまでは捨てない() {
		var buffer: RingBuffer<Int> = .init(capacity: 3)

		#expect(buffer.append(1) == nil)
		#expect(buffer.append(2) == nil)
		#expect(buffer.append(3) == nil)

		#expect(buffer.isFull)
		#expect(Array(buffer) == [1, 2, 3])
	}


	@Test func 満杯で入れるといちばん古い要素を捨てて返す() {
		var buffer: RingBuffer<Int> = .init(capacity: 3, [1, 2, 3])

		#expect(buffer.append(4) == 1)
		#expect(buffer.append(5) == 2)

		#expect(Array(buffer) == [3, 4, 5])
		#expect(buffer.first == 3)
		#expect(buffer.last == 5)
		#expect(buffer.count == 3)
	}


	@Test func 容量1でも動く() {
		var buffer: RingBuffer<String> = .init(capacity: 1)

		#expect(buffer.append("a") == nil)
		#expect(buffer.append("b") == "a")
		#expect(Array(buffer) == ["b"])
	}


	@Test func 両端から取り出す() {
		var buffer: RingBuffer<Int> = .init(capacity: 4, 1...6)

		#expect(buffer.popFirst() == 3)
		#expect(buffer.popLast() == 6)
		#expect(Array(buffer) == [4, 5])
		#expect(!buffer.isFull)

		// 空きができたので、捨てずに入る
		#expect(buffer.append(7) == nil)
		#expect(Array(buffer) == [4, 5, 7])
	}


	@Test func 空から取り出すとnil() {
		var buffer: RingBuffer<Int> = .init(capacity: 2)

		#expect(buffer.popFirst() == nil)
		#expect(buffer.popLast() == nil)
	}


	@Test func removeAllの後も容量は変わらない() {
		var buffer: RingBuffer<Int> = .init(capacity: 3, [1, 2, 3])

		buffer.removeAll()

		#expect(buffer.isEmpty)
		#expect(buffer.capacity == 3)

		buffer.append(contentsOf: [4, 5, 6, 7])
		#expect(Array(buffer) == [5, 6, 7])
	}


	// MARK: - 添字


	@Test func 添字はいちばん古い要素が0() {
		var buffer: RingBuffer<Int> = .init(capacity: 3, 1...5)

		#expect(buffer[0] == 3)
		#expect(buffer[2] == 5)

		buffer[1] = 40
		#expect(Array(buffer) == [3, 40, 5])
	}


	// MARK: - 値の意味


	@Test func 容量と要素が同じなら等しい() {
		let a: RingBuffer<Int> = .init(capacity: 3, 1...5)
		let b: RingBuffer<Int> = .init(capacity: 3, [3, 4, 5])
		let otherCapacity: RingBuffer<Int> = .init(capacity: 4, [3, 4, 5])

		#expect(a == b)
		#expect(a.hashValue == b.hashValue)
		#expect(a != otherCapacity)
	}


	@Test func コピーは元に影響しない() {
		var original: RingBuffer<Int> = .init(capacity: 2, [1, 2])
		var copy: RingBuffer<Int> = original

		copy.append(3)
		_ = original.popLast()

		#expect(Array(original) == [1])
		#expect(Array(copy) == [2, 3])
	}


	@Test func descriptionは配列と同じ() {
		let buffer: RingBuffer<Int> = .init(capacity: 3, [1, 2])

		#expect(buffer.description == "[1, 2]")
	}

}
