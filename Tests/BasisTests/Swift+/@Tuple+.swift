import Basis


@Suite struct SwiftTupleTests {
	
	@Test func equals_value() {
		#expect((1, 2) == (1, 2))
	}
	
	@Test func equals_optional() {
		let value: (Int, Int)? = (1, 2)
		let none: (Int, Int)? = nil

		#expect(value == value)
		#expect(value != none)
		#expect(none != value)
		#expect(none != value)
	}
	
	@Test func equals_array() {
		#expect([(1, 2)] == [(1, 2)])
	}
	
}

