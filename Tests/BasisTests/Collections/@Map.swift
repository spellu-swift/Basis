@testable import Basis


@Suite struct MapTests {

	@Test func Dictionaryのマージ() {
		マージを検証(Dictionary<String, Int>.self)
	}

	@Test func OrderedDictionaryのマージ() {
		マージを検証(OrderedDictionary<String, Int>.self)
	}

	private func マージを検証<M>(
		_ type: M.Type,
	) where M : Map, M.Key == String, M.Value == Int {
		let original: M = .init([("a", 1)])
		let pairs: [(String, Int)] = [("a", 2), ("b", 3), ("a", 4)]
		let optionalPairs: [(String, Int?)]
		= [("a", nil), ("a", 2), ("b", 3), ("c", nil), ("a", 4)]
		let dictionary: [String : Int] = ["a": 6, "b": 3]
		let ordered: OrderedDictionary<String, Int>
		= .init([("a", 6), ("b", 3)])
		let optionalDictionary: [String : Int?]
		= ["a": 6, "b": 3, "c": nil]
		let optionalOrdered: OrderedDictionary<String, Int?>
		= .init([("a", 6), ("b", 3), ("c", nil)])

		func 確認(
			_ result: M,
		) {
			#expect(result["a"] == 7)
			#expect(result["b"] == 3)
			#expect(result["c"] == nil)
			#expect(Array(result).count == 2)
		}

		確認(original.merging(pairs, choice: +))
		確認(original.merging(optionalPairs, choice: +))
		確認(original.merging(dictionary, choice: +))
		確認(original.merging(ordered, choice: +))
		確認(original.merging(optionalDictionary, choice: +))
		確認(original.merging(optionalOrdered, choice: +))

		var result: M = original
		result.merge(pairs, choice: +)
		確認(result)
		result = original
		result.merge(optionalPairs, choice: +)
		確認(result)
		result = original
		result.merge(dictionary, choice: +)
		確認(result)
		result = original
		result.merge(ordered, choice: +)
		確認(result)
		result = original
		result.merge(optionalDictionary, choice: +)
		確認(result)
		result = original
		result.merge(optionalOrdered, choice: +)
		確認(result)

		let empty: [(String, Int)] = []
		let emptyResult: M = original.merging(empty) { _, _ in
			Issue.record("空入力ではchoiceを呼ばない")
			return 0
		}
		#expect(emptyResult["a"] == 1)
		#expect(Array(emptyResult).count == 1)
		#expect(original["a"] == 1)
		#expect(original["b"] == nil)
	}

	@Test func マージで挿入順序を保持する() {
		let original: OrderedDictionary<String, Int>
		= .init([("a", 1), ("b", 2)])
		let result: OrderedDictionary<String, Int>
		= original.merging([("b", 3), ("c", 4), ("a", 5)], choice: +)

		#expect(result.keys == ["a", "b", "c"])
		#expect(result.values == [6, 5, 4])
		#expect(original.keys == ["a", "b"])
		#expect(original.values == [1, 2])
	}

}
