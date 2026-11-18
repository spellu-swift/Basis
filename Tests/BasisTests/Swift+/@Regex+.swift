@testable import Basis


/// Regex拡張のテスト
@Suite struct SwiftRegexTests {
	
	
	@Test	func BareSlashRegex_firstMatch() throws {
		guard
			let match: Regex<(Substring, Substring)>.Match = "abc".firstMatch(of: #/\w(\w)\w/#)
		else { return }
		
		#expect(match.substrings == ["abc", "b"])
		#expect(match.strings == ["abc", "b"])
		#expect(match.string(at: 0) == "abc")
		#expect(match.string(at: 1) == "b")
		#expect(match.string(at: 2) == nil)
//		#expect(match.range == 0..<2)
	}
	
	
	@Test	func StringRegex_firstMatch() throws {
		guard
			let match: Regex<AnyRegexOutput>.Match = "abc".firstMatch(of: try Regex(#"\w(\w)\w"#))
		else { return }
		
		#expect(match.substrings == ["abc", "b"])
		#expect(match.strings == ["abc", "b"])
		#expect(match.string(at: 0) == "abc")
		#expect(match.string(at: 1) == "b")
		#expect(match.string(at: 2) == nil)
//		#expect(match.range == 0..<2)
	}
	
	
	@Test	func StringRegex_matches() throws {
		let matches: [Regex<AnyRegexOutput>.Match] = "abc".matches(of: try Regex(#"\w(\w)\w"#))
		
		#expect(matches.count == 1)
		#expect(matches[0].strings == ["abc", "b"])
	}
	
	
}
