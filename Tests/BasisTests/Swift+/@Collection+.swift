import Basis


struct CollectionPlusTests {

	@Test func isNotEmpty() throws {
		#expect([].isNotEmpty == false)
		#expect([1, 2, 3].isNotEmpty == true)

		#expect("".isNotEmpty == false)
		#expect("123".isNotEmpty == true)
	}

	@Test func remove_1() throws {
		var a = [1, 2, 3]
		a.remove(1...)
		
		var b = "str"
		b.remove(2...)
	}

	@Test func remove_last() throws {
		var a = [1, 2, 3]
		a.remove(last: 1)
		#expect(a == [1, 2])
	}

//	@Test func sort_1() throws {
//		let dic: [String : String] = [:]
//
//		let arr: [String] = []
////		arr.sort
////		dic.sort
//	}

	@Test func binarySearch_1() throws {
		#expect(
			([] as [Int]).binarySearch(101) == .notFound(0)
		)
		
		#expect(
			([101]).binarySearch(100) == .notFound(0)
		)
		#expect(
			([101]).binarySearch(101) == .found(0)
		)
		#expect(
			([101]).binarySearch(102) == .notFound(1)
		)
		
		#expect(
			([101, 103]).binarySearch(100) == .notFound(0)
		)
		#expect(
			([101, 103]).binarySearch(101) == .found(0)
		)
		#expect(
			([101, 103]).binarySearch(102) == .notFound(1)
		)
		#expect(
			([101, 103]).binarySearch(103) == .found(1)
		)
		#expect(
			([101, 103]).binarySearch(104) == .notFound(2)
		)
	}
	
}


