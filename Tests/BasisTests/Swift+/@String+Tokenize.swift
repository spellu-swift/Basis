@testable import Basis


@Suite struct SwiftStringTests {}


extension SwiftStringTests {
	

	@Test func _1() {
		
		let tokens = "a b c".tokenize(
			rules: [(#"\w+"#, { $0[0].substring!.asString })]
		) {
			$0
		}
		
		#expect(
			tokens.count == 5
		)
		#expect(
			tokens[0].content == "a"
		)
		#expect(
			tokens[2].content == "b"
		)
		#expect(
			tokens[4].content == "c"
		)
	}
	
	
}



extension SwiftStringTests {

	@Test
	func tokenize_ignores_empty_matches() {
		let tokens = "baac".tokenize(
			rules: [
				("", { _ in "empty" }),
				("a*", { $0[0].substring!.asString }),
			]
		) { $0 }

		#expect(tokens.map(\.content) == ["b", "aa", "c"])
		#expect(tokens.allSatisfy { !$0.range.isEmpty })
	}

	@Test
	func tokenize_empty_rule_uses_default() {
		let tokens = "abc".tokenize(rules: [("^", { _ in "empty" })]) { $0 }

		#expect(tokens.map(\.content) == ["abc"])
	}
}
