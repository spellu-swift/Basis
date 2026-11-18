@testable import Basis


extension SwiftStringTests {

	
	@Test func typeName_1() async throws {
		#expect(String(describing: A.self) == "A")
		#expect(String(typeOf: A()) == "A")
//		#expect(String(typeName: A.self) == "A")
//		#expect(String(typeNameWithoutGenerics: A.self) == "A")
	}

	@Test func typeName_2() async throws {
		#expect(String(describing: B_9<Int>.self) == "B_9<Int>")
		#expect(String(typeOf: B_9<Int>()) == "B_9<Int>")
//		#expect(String(typeName: B_9<Int>.self) == "B_9<Int>")
//		#expect(String(typeNameWithoutGenerics: B_9<Int>.self) == "B_9")
	}
	
	
}


private struct A {}
private struct B_9<T> {}
