import Basis


@Suite struct DirectoryTests {
	
	@Test
	func createDirectory() throws {
		try sandbox(name: #function) { directory in
			// 単階層のパス
			try directory.createDirectory("foo")
			
			// 複階層のパス
			try directory.createDirectory("bar/a/b")
			
			#expect(directory["bar/a/b"].exists)

			// 既に存在している場合
			try directory.createDirectory("bar/a/b")

			#expect(directory["bar/a/b"].exists)
		}
	}
	
}
