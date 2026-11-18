@testable import Basis
// import Libc


@Suite struct 明示的パス解決テスト {
	@Test(arguments: ["/work/project", "/work/project/"])
	func ディレクトリ基準では末尾要素を保持する(_ base: String) {
		let directory: FilePath = .init(base)
		let path: FilePath = "child"
		#expect(
			path.resolved(relativeTo: directory, as: .directory)
				== FilePath("/work/project/child")
		)
		#expect(
			path.absoluted(relativeTo: directory, as: .directory)
				== FilePath("/work/project/child")
		)
		#expect(
			FilePath(relativeTo: directory, as: .directory, "child")
				== FilePath("/work/project/child")
		)
		#expect(
			FilePath.resolvePath(
				relativeTo: base,
				as: .directory,
				path: "child"
			)
				== "/work/project/child"
		)
	}

	@Test(arguments: ["/work/project/file", "/work/project/file/"])
	func ファイル基準では親を使用する(_ base: String) {
		let file: FilePath = .init(base)
		let path: FilePath = "child"
		#expect(
			path.resolved(relativeTo: file, as: .file)
				== "/work/project/child"
		)
		#expect(
			path.absoluted(relativeTo: file, as: .file)
				== "/work/project/child"
		)
		#expect(
			FilePath(relativeTo: file, as: .file, "child")
				== "/work/project/child"
		)
		#expect(
			FilePath.resolvePath(
				relativeTo: base,
				as: .file,
				path: "child"
			)
				== "/work/project/child"
		)
	}

	@Test func StringとFilePathの基準を同じKindで指定できる() {
		let base: String = "/work/base"
		let typedBase: FilePath = .init(base)
		for (kind, expected): (FilePath.Kind, String) in [
			(.directory, "/work/base/child"),
			(.file, "/work/child"),
		] {
			let path: FilePath = "child"
			#expect(
				path.resolved(relativeTo: base, as: kind)
					.asString == expected
			)
			#expect(
				path.resolved(relativeTo: typedBase, as: kind)
					.asString == expected
			)
			#expect(
				path.absoluted(relativeTo: base, as: kind)
					.asString == expected
			)
			#expect(
				path.absoluted(relativeTo: typedBase, as: kind)
					.asString == expected
			)
			#expect(
				FilePath(relativeTo: base, as: kind, "child")
					.asString == expected
			)
			#expect(
				FilePath(
					relativeTo: typedBase,
					as: kind,
					"child"
				).asString == expected
			)
			#expect(
				File(at: "child").absoluted(
					relativeTo: typedBase,
					as: kind
				)
				.path.asString == expected
			)
			#expect(
				Directory(at: "child").absoluted(
					relativeTo: typedBase,
					as: kind
				)
				.path.asString == expected
			)
		}
	}

	@Test(arguments: ["/work/base", "/work/base/"])
	func Kindの省略とnil指定では末尾スラッシュから判断する(_ base: String) {
		let typed: FilePath = .init(base)
		let expected: String =
			base.hasSuffix("/")
			? "/work/base/child" : "/work/child"
		let path: FilePath = "child"
		#expect(path.resolved(relativeTo: base).asString == expected)
		#expect(
			path.resolved(relativeTo: base, as: nil).asString
				== expected
		)
		#expect(path.resolved(relativeTo: typed).asString == expected)
		#expect(
			path.resolved(relativeTo: typed, as: nil).asString
				== expected
		)
		#expect(path.absoluted(relativeTo: base).asString == expected)
		#expect(
			path.absoluted(relativeTo: base, as: nil).asString
				== expected
		)
		#expect(path.absoluted(relativeTo: typed).asString == expected)
		#expect(
			path.absoluted(relativeTo: typed, as: nil).asString
				== expected
		)
		#expect(
			FilePath(relativeTo: base, "child").asString == expected
		)
		#expect(
			FilePath(relativeTo: typed, as: nil, "child").asString
				== expected
		)
		#expect(
			File(at: "child").absoluted(relativeTo: base).path
				.asString == expected
		)
		#expect(
			File(at: "child").absoluted(relativeTo: typed, as: nil)
				.path.asString == expected
		)
		#expect(
			Directory(at: "child").absoluted(relativeTo: base).path
				.asString == expected
		)
		#expect(
			Directory(at: "child").absoluted(
				relativeTo: typed,
				as: nil
			).path.asString == expected
		)
		#expect(
			FilePath.resolvePath(relativeTo: base, path: "child")
				== expected
		)
		#expect(
			FilePath.resolvePath(
				relativeTo: base,
				as: nil,
				path: "child"
			) == expected
		)
	}

	@Test func 明示指定が末尾スラッシュによる推測より優先する() {
		let path: FilePath = "child"
		#expect(
			path.resolved(relativeTo: "/work/base", as: .directory)
				== "/work/base/child"
		)
		#expect(
			path.resolved(relativeTo: "/work/base/", as: .file)
				== "/work/child"
		)
		#expect(path.resolved(relativeTo: "/") == "/child")
		#expect(FilePath(".").absoluted.asString == POSIX.getcwd())
	}

	@Test func 空入力と現在位置と親と絶対パスと未作成パスを扱う() {
		let base: FilePath = "/work/project"
		for path in ["", "."] {
			#expect(
				FilePath(path).absoluted(
					relativeTo: base,
					as: .directory
				) == base
			)
		}
		#expect(
			FilePath("./child").absoluted(
				relativeTo: base,
				as: .directory
			)
				== "/work/project/child"
		)
		#expect(
			FilePath("../child").absoluted(
				relativeTo: base,
				as: .directory
			)
				== "/work/project/../child"
		)
		#expect(
			FilePath("missing/new").absoluted(
				relativeTo: base,
				as: .directory
			)
				== "/work/project/missing/new"
		)
		#expect(
			FilePath("/elsewhere/../file").absoluted(
				relativeTo: base,
				as: .directory
			)
				== "/elsewhere/../file"
		)
		#expect(
			FilePath("child").absoluted(
				relativeTo: "/",
				as: .directory
			)
				== "/child"
		)
		#expect(
			FilePath("child").resolved(
				relativeTo: "relative/dir",
				as: .directory
			)
				== "relative/dir/child"
		)
		#expect(
			FilePath("child").resolved(
				relativeTo: "relative/file",
				as: .file
			)
				== "relative/child"
		)
	}

	@Test func カレント基準の絶対化でディレクトリ名を落とさない() {
		let cwd: String = POSIX.getcwd()
		#expect(FilePath(".").absoluted.asString == cwd)
		#expect(
			FilePath("child").absoluted.asString
				== FilePath.join(cwd, ["child"])
		)
		#expect(File(at: ".").absoluted.path.asString == cwd)
		#expect(Directory(at: ".").absoluted.path.asString == cwd)
		#expect(
			TemporaryPath.absolute("child").asString
				== FilePath.join(cwd, ["child"])
		)
	}

	@Test func ファイルとディレクトリのラッパーも明示した基準を使う() {
		#expect(
			File(at: "child").absoluted(
				relativeTo: "/work/dir",
				as: .directory
			)
			.path == "/work/dir/child"
		)
		#expect(
			File(at: "child").absoluted(
				relativeTo: "/work/file",
				as: .file
			)
			.path == "/work/child"
		)
		#expect(
			Directory(at: "child").absoluted(
				relativeTo: "/work/dir",
				as: .directory
			)
			.path == "/work/dir/child"
		)
		#expect(
			Directory(at: "child").absoluted(
				relativeTo: "/work/file",
				as: .file
			)
			.path == "/work/child"
		)
		#expect(Directory(at: "link/../child").path == "link/../child")
		#expect(File(at: "link/../child").path == "link/../child")
	}


	@Test func URIのファイル変換は現在位置を保持しURIの解決規則は変えない() throws {
		#expect(URI.file(".").filePath?.asString == POSIX.getcwd())
		#expect(
			URI.file("child").filePath?.asString
				== FilePath.join(POSIX.getcwd(), ["child"])
		)
		let child: URI = try .parse("child")
		#expect(
			child.resolved(
				against: try .parse("https://example.com/work/")
			)
				== (try URI.parse(
					"https://example.com/work/child"
				))
		)
		#expect(
			child.resolved(
				against: try .parse("https://example.com/work")
			)
				== (try URI.parse("https://example.com/child"))
		)
	}
}


import Libc

@Suite struct ファイルシステムのパス解決テスト {
	@Test func 相対リンクの基準はリンク自身の親になる() throws {
		try Directory.withTemporary { root in
			try root[directory: "dir"].createDirectory()
			try root[file: "target"].save("target")
			let link: File = root[file: "dir/link"]
			try link.createSymlink(of: "../target")
			#expect(
				link.linkTarget
					== root[file: "target"].path.realpath
			)
			let directoryLink: FilePath = root[
				path: "directory-link"
			]
			#expect(
				Libc.symlink("dir", directoryLink.asString) == 0
			)
			#expect(
				Directory(at: directoryLink).linkTarget?
					.realpath
					== root[path: "dir"].realpath
			)
		}
	}

	@Test func リンクを含む親参照の意味を絶対化で変えない() throws {
		try Directory.withTemporary { root in
			try root[directory: "target/sub"].createDirectory()
			try root[file: "target/value"].save("correct")
			try root[file: "value"].save("wrong")
			#expect(
				Libc.symlink(
					"target/sub",
					root[path: "link"].asString
				) == 0
			)
			let path: FilePath = FilePath("link/../value")
				.absoluted(
					relativeTo: root.path,
					as: .directory
				)
			#expect(try path.file.load().asString == "correct")
		}
	}
}
