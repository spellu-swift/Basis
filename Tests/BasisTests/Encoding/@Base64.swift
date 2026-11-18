@testable import Basis


@Suite struct Base64Tests {
	
	@Test
	func example() throws {
		let word: String = "ほげたら"

		#expect(
			word.base64Binary
			==
			[52, 52, 71, 55, 52, 52, 71, 83, 52, 52, 71, 102, 52, 52, 75, 74]
		)
		#expect(
			word.base64String
			==
			"44G744GS44Gf44KJ"
		)

		#expect(
			word.asBinary.base64Binary
			==
			[52, 52, 71, 55, 52, 52, 71, 83, 52, 52, 71, 102, 52, 52, 75, 74]
		)
		#expect(
			word.asBinary.base64String
			==
			"44G744GS44Gf44KJ"
		)
	}
		
}
