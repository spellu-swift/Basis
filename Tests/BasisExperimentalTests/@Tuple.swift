import BasisExperimental
import UnitTesting


@Suite struct TupleTests {

	@Suite struct Units {

		@Test func タプルから初期化してValueを読み書きできる() {
			var tuple: Tuple<Int, String> = .init(value: (1, "a"))
			let value: Tuple<Int, String>.Value = (2, "b")
			// Swift 6.4では#expect(tuple.value.0 == 1)のコード生成が
			// クラッシュするため、マクロに渡す前に要素を取り出す。
			let (first, second) = tuple.value

			#expect(first == 1)
			#expect(second == "a")
			tuple.value = value
			let (updatedFirst, updatedSecond) = tuple.value
			#expect(updatedFirst == 2)
			#expect(updatedSecond == "b")
			// tuple.value.1.append("c")もSwift 6.4のコード生成で
			// クラッシュするため、取り出したタプルを変更して再代入する。
			var updated: Tuple<Int, String>.Value = tuple.value
			updated.1.append("c")
			tuple.value = updated
			let (_, finalSecond) = tuple.value
			#expect(finalSecond == "bc")
		}

		@Test func 個別の要素から型を推論して初期化できる() {
			let tuple = Tuple(1, "a", true)
			let expected: Tuple<Int, String, Bool>
			= .init(value: (1, "a", true))

			#expect(tuple == expected)
		}

		@Test func 二要素を両方の初期化方法で作れる() {
			let tuple: Tuple<Int, String> = .init(value: (1, "a"))
			let elements: Tuple<Int, String> = .init(1, "a")

			#expect(tuple == elements)
			#expect(tuple.debugDescription == "(1, \"a\")")
		}

		@Test func Equatableだけに適合する要素を比較できる() {
			let lhs: Tuple<EqualityOnly, EqualityOnly, EqualityOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 3))
			let equal: Tuple<EqualityOnly, EqualityOnly, EqualityOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 3))
			let different: Tuple<EqualityOnly, EqualityOnly, EqualityOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 4))

			#expect(lhs == equal)
			#expect(lhs != different)
		}

		@Test func Hashableだけに適合する要素をキーにできる() {
			let key: Tuple<HashOnly, String> = .init(
				value: (.init(value: 1), "a"),
			)
			var values: [Tuple<HashOnly, String> : Int] = [key: 1]

			values[.init(value: (.init(value: 1), "a"))] = 2
			values[.init(value: (.init(value: 2), "a"))] = 3
			values[.init(value: (.init(value: 1), "b"))] = 4

			#expect(values.count == 3)
			#expect(values[key] == 2)
			#expect(values[.init(value: (.init(value: 2), "a"))] == 3)
			#expect(values[.init(value: (.init(value: 1), "b"))] == 4)
		}

		@Test func hashへ直接渡しても等しい値は同じ結果になる() {
			let lhs: Tuple<Int, String> = .init(value: (1, "a"))
			let rhs: Tuple<Int, String> = .init(1, "a")
			var lhsHasher: Hasher = .init()
			var rhsHasher: Hasher = lhsHasher

			lhs.hash(into: &lhsHasher)
			rhs.hash(into: &rhsHasher)

			#expect(lhsHasher.finalize() == rhsHasher.finalize())
		}

		@Test func Comparableだけに適合する要素を整列できる() {
			let lower: Tuple<ComparableOnly, ComparableOnly, ComparableOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 3))
			let upper: Tuple<ComparableOnly, ComparableOnly, ComparableOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 4))

			#expect(lower < upper)
			#expect(lower <= upper)
			#expect(upper > lower)
			#expect(upper >= lower)
			#expect(lower <= lower)
			#expect(lower >= lower)
			#expect(!(lower < lower))
			#expect(!(lower > lower))
			#expect([upper, lower].sorted() == [lower, upper])
		}

		@Test func Orderableだけに適合する要素を三方比較できる() {
			let lower: Tuple<OrderOnly, OrderOnly, OrderOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 3))
			let upper: Tuple<OrderOnly, OrderOnly, OrderOnly>
			= .init(.init(value: 1), .init(value: 2), .init(value: 4))

			#expect((lower <=> upper) == .less)
			#expect((upper <=> lower) == .greater)
			#expect((lower <=> lower) == .equal)
		}

		@Test func Sendableだけに適合する要素を別タスクへ渡せる() async {
			let tuple: Tuple<SendableOnly, String> = .init(
				value: (.init(value: 7), "a"),
			)
			let received = await Task.detached { tuple }.value
			let (object, text) = received.value

			#expect(object.value == 7)
			#expect(text == "a")
		}

		@Test func デバッグ表示には要素が順に含まれる() {
			let pair: Tuple<Int, String> = .init(1, "a")
			let triple: Tuple<Int, String, Bool> = .init(1, "a", true)
			let opaque: Tuple<DisplayOnly, DisplayOnly>
			= .init(.init(), .init())

			#expect(pair.debugDescription == "(1, \"a\")")
			#expect(triple.debugDescription == "(1, \"a\", true)")
			#expect(opaque.debugDescription == "(表示専用, 表示専用)")
		}
	}

	@Suite struct Semantics {

		@Test func 二要素のTupleは両方が等しければ等しい() {
			let lhs: Tuple<Int, String> = .init(1, "a")
			let rhs: Tuple<Int, String> = .init(value: (1, "a"))

			#expect(lhs == rhs)
			#expect(!(lhs < rhs))
			#expect(lhs <= rhs)
			#expect(lhs >= rhs)
			#expect(!(lhs > rhs))
			#expect((lhs <=> rhs) == .equal)
			#expect(Set([lhs, rhs]).count == 1)
		}

		@Test func 異種の要素を先頭から辞書式に比較する() {
			let first: Tuple<Int, String, Int> = .init(value: (1, "z", 1))
			let second: Tuple<Int, String, Int> = .init(value: (2, "a", 0))
			let third: Tuple<Int, String, Int> = .init(value: (2, "b", 0))
			let fourth: Tuple<Int, String, Int> = .init(value: (2, "b", 1))

			#expect([fourth, third, second, first].sorted()
				== [first, second, third, fourth])
			#expect((first <=> second) == .less)
			#expect((third <=> second) == .greater)
			#expect((third <=> fourth) == .less)
			#expect((fourth <=> fourth) == .equal)
			#expect(first != second)
			#expect(second != third)
			#expect(third != fourth)
		}

		@Test func 七要素でも末尾まで比較とハッシュに参加する() {
			let lhs = Tuple(1, 2, 3, 4, 5, 6, 7)
			let equal = Tuple(1, 2, 3, 4, 5, 6, 7)
			let rhs = Tuple(1, 2, 3, 4, 5, 6, 8)

			#expect(lhs == equal)
			#expect(lhs != rhs)
			#expect(lhs < rhs)
			#expect((lhs <=> rhs) == .less)
			#expect(Set([lhs, equal, rhs]).count == 2)
		}

		@Test func 差が確定した後の要素は比較しない() {
			let lhs: Tuple<Int, ComparisonForbidden>
			= .init(value: (1, .init()))
			let rhs: Tuple<Int, ComparisonForbidden>
			= .init(value: (2, .init()))

			#expect(lhs != rhs)
			#expect(lhs < rhs)
			#expect((lhs <=> rhs) == .less)
		}
	}
}


private struct EqualityOnly : Equatable {
	var value: Int
}


private struct HashOnly : Hashable {
	var value: Int
}


private struct ComparableOnly : Comparable {
	var value: Int

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.value < rhs.value
	}
}


private struct OrderOnly : Orderable {
	var value: Int

	static func <=> (lhs: Self, rhs: Self) -> Ordering {
		lhs.value <=> rhs.value
	}
}


private final class SendableOnly : Sendable {
	let value: Int

	init(value: Int) {
		self.value = value
	}
}


private struct DisplayOnly : CustomStringConvertible {
	var description: String { "表示専用" }
}


private struct ComparisonForbidden : Comparable, Orderable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		Issue.record("差が確定した後に等価比較された")
		return true
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		Issue.record("差が確定した後に大小比較された")
		return false
	}

	static func <=> (lhs: Self, rhs: Self) -> Ordering {
		Issue.record("差が確定した後に三方比較された")
		return .equal
	}
}
