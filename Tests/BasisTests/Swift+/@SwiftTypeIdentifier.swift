@testable import Basis


@Suite struct SwiftTypeIdentifierTests {
	
	struct InnerType {}

	@Test func normalType() async throws {
		let type = SwiftTypeIdentifier(String.self)

		#expect(type.components == ["Swift", "String"])
		#expect(type.name == "String")
		#expect(type.nameInModule == "String")
		#expect(type.fullQualifiedName == "Swift.String")
		#expect(type.generics == [])

		#expect(String(describing: String.self) == "String")
		#expect(String(reflecting: String.self) == "Swift.String")
	}
	
	@Test func innerType() async throws {
		let type = SwiftTypeIdentifier(InnerType.self)
		
		#expect(type.components == ["BasisTests", "SwiftTypeIdentifierTests", "InnerType"])
		#expect(type.name == "InnerType")
		#expect(type.nameInModule == "SwiftTypeIdentifierTests.InnerType")
		#expect(type.fullQualifiedName == "BasisTests.SwiftTypeIdentifierTests.InnerType")
		#expect(type.generics == [])

		#expect(String(describing: InnerType.self) == "InnerType")
		#expect(String(reflecting: InnerType.self) == "BasisTests.SwiftTypeIdentifierTests.InnerType")
	}
	
	@Test func genericsType() async throws {
		let type = SwiftTypeIdentifier(Dictionary<String, Int>.self)
		
		#expect(type.components == ["Swift", "Dictionary"])
		#expect(type.name == "Dictionary")
		#expect(type.nameInModule == "Dictionary")
		#expect(type.fullQualifiedName == "Swift.Dictionary")
		#expect(type.generics.map(\.components) == [
			["Swift", "String"],
			["Swift", "Int"],
		])

		#expect(String(describing: Dictionary<String, Int>.self) == "Dictionary<String, Int>")
		#expect(String(reflecting: Dictionary<String, Int>.self) == "Swift.Dictionary<Swift.String, Swift.Int>")
	}
	
	@Test func value() async throws {
		let string: any StringProtocol = ""
		
		#expect(SwiftTypeIdentifier.of(string).fullQualifiedName == "Swift.String")
	}

}

