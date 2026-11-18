@testable import Basis


@Suite struct RangeSetTests {

	@Test func 範囲を正規化して保持する() {
		let set: RangeSet<Int> = .init([5 ..< 8, 1 ..< 3, 3 ..< 4, 7 ..< 10, 12 ..< 12])

		#expect(Array(set.ranges) == [1 ..< 4, 5 ..< 10])
		#expect(set.ranges.count == 2)
		#expect(set.isEmpty == false)
		#expect(RangeSet<Int>().isEmpty)
		#expect(RangeSet(3 ..< 3).isEmpty)
	}


	@Test func 値が含まれているか調べる() {
		let set: RangeSet<Int> = .init([1 ..< 4, 5 ..< 10])

		#expect(set.contains(1))
		#expect(set.contains(3))
		#expect(set.contains(4) == false)
		#expect(set.contains(9))
		#expect(set.contains(10) == false)
		#expect(set.contains(0) == false)
	}


	@Test func 範囲を追加と削除する() {
		var set: RangeSet<Int> = .init(0 ..< 10)

		set.remove(contentsOf: 3 ..< 5)
		#expect(Array(set.ranges) == [0 ..< 3, 5 ..< 10])

		set.insert(contentsOf: 3 ..< 4)
		#expect(Array(set.ranges) == [0 ..< 4, 5 ..< 10])

		set.insert(contentsOf: 4 ..< 5)
		#expect(Array(set.ranges) == [0 ..< 10])
	}


	@Test func 集合演算() {
		let a: RangeSet<Int> = .init([0 ..< 5, 10 ..< 15])
		let b: RangeSet<Int> = .init([3 ..< 12])

		#expect(Array(a.union(b).ranges) == [0 ..< 15])
		#expect(Array(a.intersection(b).ranges) == [3 ..< 5, 10 ..< 12])
		#expect(Array(a.subtracting(b).ranges) == [0 ..< 3, 12 ..< 15])
		#expect(Array(a.symmetricDifference(b).ranges) == [0 ..< 3, 5 ..< 10, 12 ..< 15])

		var c: RangeSet<Int> = a
		c.formUnion(b)
		#expect(c == a.union(b))

		c = a
		c.subtract(b)
		#expect(c == a.subtracting(b))
	}


	@Test func 標準ライブラリのRangeSetと結果が一致する() throws {
		guard #available(macOS 15, iOS 18, *) else { return }

		var random: SystemRandomNumberGenerator = .init()

		func ranges() -> [Range<UInt32>] {
			(0 ..< Int.random(in: 0 ... 6, using: &random)).map { _ in
				let lower: UInt32 = .random(in: 0 ..< 60, using: &random)
				return lower ..< lower + .random(in: 0 ..< 15, using: &random)
			}
		}

		for _ in 0 ..< 2_000 {
			let x: [Range<UInt32>] = ranges()
			let y: [Range<UInt32>] = ranges()

			let a: RangeSet<UInt32> = .init(x)
			let b: RangeSet<UInt32> = .init(y)
			let p: Swift.RangeSet<UInt32> = .init(x)
			let q: Swift.RangeSet<UInt32> = .init(y)

			#expect(Array(a.ranges) == Array(p.ranges), "\(x)")
			#expect(Array(a.union(b).ranges) == Array(p.union(q).ranges), "\(x) \(y)")
			#expect(Array(a.intersection(b).ranges) == Array(p.intersection(q).ranges), "\(x) \(y)")
			#expect(Array(a.subtracting(b).ranges) == Array(p.subtracting(q).ranges), "\(x) \(y)")
			#expect(Array(a.symmetricDifference(b).ranges) == Array(p.symmetricDifference(q).ranges), "\(x) \(y)")

			for value: UInt32 in 0 ..< 80 {
				#expect(a.contains(value) == p.contains(value))
			}
		}
	}

}
