import Basis
import Libc


@Suite struct FileStatusIdentityTests {

	private func status(
		_ path: FilePath,
		followLink: Bool = false,
	) throws -> FileStatus {
		try #require(FileStatus(at: path, followLink: followLink))
	}


	@Test func 同じファイルはisSame() throws {
		try sandbox(name: #function) { directory in
			let path: FilePath = directory.path["a.txt"]
			try path.file.save("a")

			#expect(try status(path).isSame(as: status(path)))
		}
	}


	@Test func 同じディレクトリは別の書き方のパスでもisSame() throws {
		try sandbox(name: #function) { directory in
			let sub: FilePath = directory.path["sub"]
			try sub.directory.createDirectory()

			let other: FilePath = .init(noCheck: sub.asString + "/../sub/.")

			#expect(try status(directory.path).isSame(as: status(directory.path)))
			#expect(try status(sub).isSame(as: status(other)))
		}
	}


	@Test func 別のファイルはisSameでない() throws {
		try sandbox(name: #function) { directory in
			let a: FilePath = directory.path["a.txt"]
			let b: FilePath = directory.path["b.txt"]
			try a.file.save("same")
			try b.file.save("same")

			#expect(try !status(a).isSame(as: status(b)))
		}
	}


	@Test func ファイルとディレクトリはisSameでない() throws {
		try sandbox(name: #function) { directory in
			let file: FilePath = directory.path["a.txt"]
			try file.file.save("a")

			#expect(try !status(file).isSame(as: status(directory.path)))
			#expect(try !status(directory.path).isSame(as: status(file)))
		}
	}


	@Test func ハードリンクはisSame() throws {
		try sandbox(name: #function) { directory in
			let original: FilePath = directory.path["a.txt"]
			let hardLink: FilePath = directory.path["b.txt"]
			try original.file.save("a")
			#expect(link(original.asString, hardLink.asString) == 0)

			#expect(try status(original).isSame(as: status(hardLink)))
		}
	}


	@Test func シンボリックリンクはfollowLinkの指定で比べる相手が変わる() throws {
		try sandbox(name: #function) { directory in
			let target: FilePath = directory.path["a.txt"]
			let symbolicLink: FilePath = directory.path["link"]
			try target.file.save("a")
			#expect(symlink(target.asString, symbolicLink.asString) == 0)

			// リンク先を比べる
			#expect(try status(symbolicLink, followLink: true).isSame(as: status(target)))
			// リンクそのものを比べる
			#expect(try !status(symbolicLink, followLink: false).isSame(as: status(target)))
			#expect(try status(symbolicLink, followLink: false).isSame(as: status(symbolicLink, followLink: false)))
		}
	}


	@Test func ディレクトリへのシンボリックリンクもリンク先と比べられる() throws {
		try sandbox(name: #function) { directory in
			let target: FilePath = directory.path["sub"]
			let symbolicLink: FilePath = directory.path["link"]
			try target.directory.createDirectory()
			#expect(symlink(target.asString, symbolicLink.asString) == 0)

			#expect(try status(symbolicLink, followLink: true).isSame(as: status(target)))
			#expect(try !status(symbolicLink, followLink: false).isSame(as: status(target)))
		}
	}


	@Test func 名前を変えても同じ実物ならisSame() throws {
		try sandbox(name: #function) { directory in
			let before: FilePath = directory.path["before"]
			let after: FilePath = directory.path["after"]
			try before.directory.createDirectory()

			let original: FileStatus = try status(before)
			#expect(rename(before.asString, after.asString) == 0)

			#expect(try original.isSame(as: status(after)))
		}
	}

}
