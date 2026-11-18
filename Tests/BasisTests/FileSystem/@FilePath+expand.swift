@testable import Basis


extension FilePathTests {

	@Test func expand() {
		#expect(
			FilePath.expand("~")
			==
			Backbone.environment["HOME"]
		)

		let root: String = try! #require(Backbone.user("root")?.user.pw_dir.asString)

		#expect(FilePath.expand("~root/foo") == root + "/foo")
	}

	@Test func POSIXのチルダ展開() {
		let values: [String : String] = ["HOME": "/home/me/"]

		#expect(FilePath.expand("~", values: values) == "/home/me/")
		#expect(FilePath.expand("~/foo", values: values) == "/home/me/foo")
		#expect(FilePath.expand("a/~/foo", values: values) == "a/~/foo")

		// HOMEがない場合と、知らないユーザーはそのまま
		#expect(FilePath.expand("~/foo", values: [:]) == "~/foo")
		#expect(FilePath.expand("~basis-no-such-user/foo", values: values) == "~basis-no-such-user/foo")

		// 値の中の~や$は展開しない
		#expect(FilePath.expand("~/x", values: ["HOME": "/$A", "A": "a"]) == "/$A/x")
	}

	@Test func POSIXの変数展開() {
		let values: [String : String] = ["Name": "upper", "name": "lower", "A": "$B", "B": "b", "A_1": "x"]

		#expect(FilePath.expand("${Name}/${name}", values: values) == "upper/lower")
		#expect(FilePath.expand("${A}", values: values) == "$B")
		#expect(FilePath.expand("$A_1.${A}_1", values: values) == "$A_1.$B_1")
		#expect(FilePath.expand("[${UNKNOWN}]", values: values) == "[]")
		#expect(FilePath.expand("$1 ${ A } $", values: values) == "$1 ${ A } $")
	}
	
	@Test func normalizePath() {
		#expect(
			FilePath.normalizePath("/a/b/c/.")
			==
			"/a/b/c/"
		)

		#expect(
			FilePath.normalizePath("/a/b/c/..")
			==
			"/a/b/"
		)
	}
	
}
