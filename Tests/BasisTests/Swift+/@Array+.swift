@testable import Basis


@Suite struct SwiftArrayTests {
	
	@Test	func first() {
		let value = [0, 1, 2]
		
//		#expect(
//			value.first(-1) == []
//		)
		#expect(
			value.first(0) == []
		)
		#expect(
			value.first(1) == [0]
		)
		#expect(
			value.first(2) == [0, 1]
		)
		#expect(
			value.first(3) == [0, 1, 2]
		)
//		#expect(
//			value.first(4) == [0, 1, 2]
//		)
	}
	
	@Test	func last() {
		let value = [0, 1, 2]
		
//		#expect(
//			value.last(-1) == []
//		)
		#expect(
			value.last(0) == []
		)
		#expect(
			value.last(1) == [2]
		)
		#expect(
			value.last(2) == [1, 2]
		)
		#expect(
			value.last(3) == [0, 1, 2]
		)
//		#expect(
//			value.last(4) == [0, 1, 2]
//		)
	}
	
	@Test	func divide_first() {
		let value = [0, 1, 2]
		
//		#expect(
//			value.divide(first: -1) == ([], [0, 1, 2])
//		)
		#expect(
			value.divide(first: 0) == ([], [0, 1, 2])
		)
		#expect(
			value.divide(first: 1) == ([0], [1, 2])
		)
		#expect(
			value.divide(first: 2) == ([0, 1], [2])
		)
		#expect(
			value.divide(first: 3) == ([0, 1, 2], [])
		)
//		#expect(
//			value.divide(first: 4) == ([0, 1, 2], [])
//		)
	}
	
	@Test
	func divide_last() {
		let value = [0, 1, 2]
		
//		#expect(
//			value.divide(last: -1) == ([0, 1, 2], [])
//		)
		#expect(
			value.divide(last: 0) == ([0, 1, 2], [])
		)
		#expect(
			value.divide(last: 1) == ([0, 1], [2])
		)
		#expect(
			value.divide(last: 2) == ([0], [1, 2])
		)
		#expect(
			value.divide(last: 3) == ([], [0, 1, 2])
		)
//		#expect(
//			value.divide(last: 4) == ([], [0, 1, 2])
//		)
	}
	
	@Test func 配列の要素書き換え() async throws {
		var a: [Int]
		
		// 1. for-in構文では配列の要素書き換えはできない
		a = [2, 4, 6]
		
		for var value in a {
			if value == 4 {
				value *= 100
			}
		}
		
		#expect(a == [2, 4, 6])
		
		// 2. forEach()で書き換えできるようにした。
		//    しかし、パフォーマンスに問題あるかも。
		a = [2, 4, 6]
		
		a.modifyAll { index, value in
			if value == 4 {
				value *= 100
			}
		}
		
		#expect(a == [2, 400, 6])
	}
	
	@Test("Swiftにおいて、使うかわからない値を返すメソッドはどれだけオーバーヘッドがあるのか？を調べる") func modify_overload() {
		var b = [1]
		b.modify(at: 0) {
			$0 = 4
		}
		print(b)
	}

}
