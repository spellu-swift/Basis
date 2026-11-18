@testable import Basis


@Suite struct CacheTests {
	
	
	@Test func useDefaultValue() {
		var cache: Cache<String, Int> = .default
		
		let foo: Int = cache["foo"]
		
		#expect(foo == Int.default)
	}
	
	
	@Test func useNoDefaultValue() {
		struct Dummy {
			var value: Int
		}

		let cache: Cache<String, Dummy> = [
			"foo" : .init(value: 3),
		]
		
		let foo: Dummy = cache["foo"]

		#expect(foo.value == 3)
	}
	
	
}
