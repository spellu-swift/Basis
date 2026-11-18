@testable import Basis


@Suite struct BinaryTests {
	
	
	@Test
	func _1() {
		let data: Binary = [1, 2, 3, 4, 1, 2, 3]
		
		#expect(
			data[...].range == 0..<data.count
		)
	}

	
	@Test
	func ArraySlice() {
		let data: [Int] = [1, 2, 3, 4, 1, 2, 3]

		let s1: ArraySlice = data[0..<2]
		let s2: ArraySlice = data[0..<2]

		#expect(
			s1 == s2
		)
	}


	@Test
	func SliceEquatable() {
		let data: Binary = [1, 2, 3, 4, 1, 2, 3]

		let s1: Slice<Binary> = data[0..<2]
		let s2: Slice<Binary> = data[0..<2]

		
		#expect(
			s1 == s2
		)

		#expect(
			data[0..<2] == data[0..<2]
		)

		#expect(
			data[0..<2] == data[4..<6]
		)

		#expect(
			data[0..<2]	!= data[3..<5]
		)

		#expect(
			data[0..<2]	!= data[...]
		)
	}
	
	
}

