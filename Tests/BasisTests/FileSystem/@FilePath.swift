import Basis


@Suite struct FilePathTests {
	
	@Test
	func PathComponents() {
		func check(
			_ value: FilePathComponents,
			absolute: Bool,
			components: [(Substring, Bool)],
			builded: String
		) {
			#expect(value.absolute == absolute)
			#expect(value.components.asOrderedDictionary() == components.asOrderedDictionary())
			#expect(value.build() == builded)
		}
		
		check(
			FilePathComponents.parse(""),
			absolute: false,
			components: [],
			builded: ""
		)
		
		check(
			FilePathComponents.parse("a"),
			absolute: false,
			components: [("a", false)],
			builded: "a"
		)
		
		check(
			FilePathComponents.parse("/"),
			absolute: true,
			components: [],
			builded: "/"
		)
		
		check(
			FilePathComponents.parse("/a/b/c"),
			absolute: true,
			components: [("a", true), ("b", true), ("c", false)],
			builded: "/a/b/c"
		)
		
		check(
			FilePathComponents.parse("/a/b/c/"),
			absolute: true,
			components: [("a", true), ("b", true), ("c", true)],
			builded: "/a/b/c/"
		)
		
		check(
			FilePathComponents.parse("a/b/c/"),
			absolute: false,
			components: [("a", true), ("b", true), ("c", true)],
			builded: "a/b/c/"
		)
		
		check(
			FilePathComponents.parse("//a//b///c///"),
			absolute: true,
			components: [("a", true), ("b", true), ("c", true)],
			builded: "/a/b/c/"
		)
	}
	
	@Test
	func normalize() {
		#expect(
			FilePath("///a/b//c///")
			==
			"/a/b/c/"
		)
		
		#expect(
			FilePath("a/b//c")
			==
			"a/b/c"
		)
	}
	
	@Test
	func resolved() {
		#expect(
			FilePath("a/b/../c")
			==
			"a/b/../c"
		)
		
		#expect(
			FilePath("a/b/../c").normalized
			==
			"a/c"
		)
		
		#expect(
			FilePath("a/b/../c/").normalized
			==
			"a/c/"
		)
	}
	
	@Test
	func split() {
		#expect(FilePath.splitPath("abc/def").0 == "abc")
		#expect(FilePath.splitPath("abc/def").1 == "def")
	}
	
	@Test
	func parts() {
		#expect(FilePath("/").parent == FilePath("/"))
		
		#expect(FilePath("abc/def.xyz").baseName                        == "abc")
		#expect(FilePath("abc/def.xyz").fileName                        == "def.xyz")
		#expect(FilePath("abc/def.xyz").fileNameWithoutExtension        == "def")
		#expect(FilePath("abc/def.xyz").extension                       == "xyz")
		
		#expect(FilePath("abc/def").extension                           == nil)
		
		#expect(FilePath("abc/def.x.y.z").extension                     == "z")
		#expect(FilePath("abc/def.x.y.z").extension(position: .last)    == "z")
		#expect(FilePath("abc/def.x.y.z").extension(position: .last(1)) == "z")
		#expect(FilePath("abc/def.x.y.z").extension(position: .last(2)) == "y.z")
		#expect(FilePath("abc/def.x.y.z").extension(position: .last(3)) == "x.y.z")
		#expect(FilePath("abc/def.x.y.z").extension(position: .last(4)) == "x.y.z")
	}
	
	@Test
	func parent() {
		#expect(FilePath("/abc/def").parent == FilePath("/abc/"))
		#expect(FilePath("/abc/def/").parent == FilePath("/abc/"))
		
		#expect(FilePath("abc/def").parent == FilePath("abc/"))
		#expect(FilePath("abc/def/").parent == FilePath("abc/"))
	}
	
	@Test
	func ancestors() {
		#expect(
			FilePath("/a/b/c").ancestors
			==
			[
				FilePath("/a"),
				FilePath("/a/b"),
			]
		)
		
		#expect(
			FilePath("a/b/c").ancestors
			==
			[
				FilePath("a"),
				FilePath("a/b"),
			]
		)
	}
	
	@Test
	func test_appending() {
		#expect(
			FilePath("abc/def").appending("xyz.json")
			==
			FilePath("abc/def/xyz.json")
		)
		#expect(
			FilePath("abc/def").appending("")
			==
			FilePath("abc/def")
		)
		#expect(
			FilePath("abc/def").appending(nil)
			==
			FilePath("abc/def")
		)

		#expect(
			FilePath("").appending("abc")
			==
			FilePath("abc")
		)
		#expect(
			FilePath("").appending("")
			==
			FilePath("")
		)
	}
	
	@Test
	func replacing() {
		#expect(
			FilePath("abc/def").replacing(fileName: "xyz.json")
			==
			FilePath("abc/xyz.json")
		)
		
		#expect(
			FilePath("abc/def.txt").replacing(fileName: "xyz.json")
			==
			FilePath("abc/xyz.json")
		)
		
		#expect(
			FilePath("abc/def").replacing(extension: "json")
			==
			FilePath("abc/def.json")
		)
		
		#expect(
			FilePath("abc/def.txt").replacing(extension: "json")
			==
			FilePath("abc/def.json")
		)
		
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json")
			==
			FilePath("abc/def.x.y.json")
		)
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json", position: .last)
			==
			FilePath("abc/def.x.y.json")
		)
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json", position: .last(1))
			==
			FilePath("abc/def.x.y.json")
		)
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json", position: .last(2))
			==
			FilePath("abc/def.x.json")
		)
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json", position: .last(3))
			==
			FilePath("abc/def.json")
		)
		#expect(
			FilePath("abc/def.x.y.z").replacing(extension: "json", position: .last(4))
			==
			FilePath("abc/def.json")
		)
	}
	
	@Test
	func divide() {
		#expect(
			FilePath("/abc/def/ghi").divide(first: 1)
			==
			(FilePath("/abc/"), ["def", "ghi"])
		)
		#expect(
			FilePath("/abc/def/ghi").divide(first: 2)
			==
			(FilePath("/abc/def/"), ["ghi"])
		)

		#expect(
			FilePath("abc/def/ghi").divide(first: 1)
			==
			(FilePath("abc/"), ["def", "ghi"])
		)
		#expect(
			FilePath("abc/def/ghi").divide(first: 2)
			==
			(FilePath("abc/def/"), ["ghi"])
		)
	}
	
	@Test
	func insert() {
		#expect(
			FilePath("/abc/def/foo.bar").insert()
			==
			FilePath("/abc/def/foo.bar")
		)
		#expect(
			FilePath("/abc/def/foo.bar").insert(prefix: "00-")
			==
			FilePath("/abc/def/00-foo.bar")
		)
		#expect(
			FilePath("/abc/def/foo.bar").insert(suffix: "-11")
			==
			FilePath("/abc/def/foo-11.bar")
		)
		#expect(
			FilePath("/abc/def/foo.bar").insert(prefix: "00-", suffix: "-11")
			==
			FilePath("/abc/def/00-foo-11.bar")
		)
	}
	
	@Test
	func FilePathを渡す添字は相対パスを結合し絶対パスはそのまま返す() {
		let base: FilePath = "/var/log"
		let relative: FilePath = "app/today.log"
		let absolute: FilePath = "/etc/hosts"

		#expect(base[relative] == "/var/log/app/today.log")
		#expect(base[absolute] == "/etc/hosts")
	}
	
}


private func check(
	at path: FilePath,
	type: FileType?,
	symlink: Bool,
) {
	let fs: FileStatus? = .init(at: path, followLink: true)

	#expect(fs != nil)
	#expect(fs?.type == type)
	#expect(fs?.symlink == symlink)
}
