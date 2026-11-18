@testable import Basis


@Suite struct StringTests {

	@Test
	func TypeName() {
		#expect(
			String(typeOf: nil) == "nil"
		)
		#expect(
			String(typeOf: 123) == "Int"
		)
		#expect(
			String(typeOf: "foo") == "String"
		)
		
		struct A {}
		#expect(
			String(typeOf: A()) == "A"
		)
		#expect(
			String(typeOf: A.self) == "A.Type"
		)
	}

}
