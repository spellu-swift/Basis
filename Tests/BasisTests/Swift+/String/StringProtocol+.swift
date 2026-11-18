

struct StringProtocolTests {
	
	@Test
	func utf8_subscript_by_Int() {
		let string = "abcde"
		
		#expect(string.utf8[1..<3].asString == "bc")
		#expect(string.utf8[1...3].asString == "bcd")
	}

	@Test
	func utf16_subscript_by_Int() {
		let string = "abcde"
		
		#expect(string.utf16[1..<3].asString == "bc")
		#expect(string.utf16[1...3].asString == "bcd")
	}

	@Test
	func scalar_subscript_by_Int() {
		let string = "abcde"
		
		#expect(string.unicodeScalars[1..<3].asString == "bc")
		#expect(string.unicodeScalars[1...3].asString == "bcd")
	}

	@Test
	func 日本語_subscript() {
		#expect("aあa".utf8[1...3].asString == "あ")
		#expect("aあa".utf16[1...1].asString == "あ")
		#expect("aあa".unicodeScalars[1...1].asString == "あ")
	}

	@Test
	func 絵文字_subscript() {
		#expect("a😀a".utf8[1...4].asString == "😀")
		#expect("a😀a".utf16[1...2].asString == "😀")
		#expect("a😀a".unicodeScalars[1...1].asString == "😀")
		#expect("a😀a".unicodeScalars[1...1].count == 1)
		#expect("a😀a".unicodeScalars[1...1].asString.count == 1)
	}

	@Test
	func 改行_subscript() {
		#expect("a\r\na".utf8[1...2].asString == "\r\n")
		#expect("a\r\na".utf8[1...2].asString.count == 1)
		#expect("a\r\na".utf16[1...2].asString == "\r\n")
		#expect("a\r\na".utf16[1...2].asString.count == 1)
		#expect("a\r\na".unicodeScalars[1...2].asString == "\r\n")
		#expect("a\r\na".unicodeScalars[1...2].count == 2)
		#expect("a\r\na".unicodeScalars[1...2].asString.count == 1)
	}

	@Test func elementsEqual() async throws {
		let string: Substring.UTF8View = "あいう".utf8[3...5]
		let substring: Substring = "い"

		#expect(string.elementsEqual(substring.utf8))
	}

}
