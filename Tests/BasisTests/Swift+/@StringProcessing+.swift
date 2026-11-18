

@Suite struct SwiftStringProcessingTests {
	
	/// Trimのテスト
	@Test	func trimming() throws {
		#expect(" abc ".trimmed(" ") == "abc")
		#expect("  abc  ".trimmed(" ") ==  " abc ")

		#expect(" abc ".trimmed(#/\s+/#) == "abc")
		#expect("  abc  ".trimmed(#/\s+/#) ==  "abc")
	}
	
}

