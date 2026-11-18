@testable import BasisUtility


struct SemanticVersionPrecedenceTests {

	@Test func 仕様の優先順位を満たす() throws {
		let strings: [String] = [
			"1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
			"1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0", "2.0.0",
			"2.1.0", "2.1.1",
		]
		let versions: [SemanticVersion] = try strings.map(SemanticVersion.parse)
		for left in versions.indices {
			for right in versions.indices {
				#expect((versions[left] < versions[right]) == (left < right))
				#expect((versions[left] == versions[right]) == (left == right))
			}
		}
	}

	@Test func メタデータは優先順位とハッシュに影響しない() throws {
		let a: SemanticVersion = try .parse("1.2.3-alpha+001")
		let b: SemanticVersion = try .parse("1.2.3-alpha+other")
		#expect(a == b)
		#expect(!(a < b) && !(b < a))
		#expect(Set([a, b]).count == 1)
		#expect([a: "value"][b] == "value")
		#expect(a.description != b.description)
	}

	@Test func 巨大な数値識別子とASCII順で比較する() throws {
		#expect(
			try SemanticVersion.parse("1.0.0-999999999999999999999999999999")
				< SemanticVersion.parse("1.0.0-1000000000000000000000000000000")
		)
		#expect(
			try SemanticVersion.parse("1.0.0-999999999999999999999999999999")
				< SemanticVersion.parse("1.0.0-a")
		)
		#expect(
			try SemanticVersion.parse("1.0.0-A")
				< SemanticVersion.parse("1.0.0-a")
		)
	}

}
