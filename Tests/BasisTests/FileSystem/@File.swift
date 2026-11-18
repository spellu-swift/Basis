import Basis
import Libc


@Suite struct FileTests {
	
	
	@Test
	func st_mode(
	) {
		#expect(S_IFMT   == 0xF000)
		#expect(S_IFIFO  == 0x1000)
		#expect(S_IFCHR  == 0x2000)
		#expect(S_IFDIR  == 0x4000)
		#expect(S_IFBLK  == 0x6000)
		#expect(S_IFREG  == 0x8000)
		#expect(S_IFLNK  == 0xA000)
		#expect(S_IFSOCK == 0xC000)
//		#expect(S_IFWHT  == 0xE000)
	}
	
	
	@Test
	func dt(
	) {
		#expect(DT_UNKNOWN == 0x0)
		#expect(DT_FIFO    == 0x1)
		#expect(DT_CHR     == 0x2)
		#expect(DT_DIR     == 0x4)
		#expect(DT_BLK     == 0x6)
		#expect(DT_REG     == 0x8)
		#expect(DT_LNK     == 0xA)
		#expect(DT_SOCK    == 0xC)
		#expect(DT_WHT     == 0xE)
	}
	
	
	@Test
	func FileStatus(
	) throws {
		check(
			at: "/",
			type: .directory, symlink: false
		)
		
		check(
			at: "/dev/ptyp0",
			type: .character, symlink: false
		)
		
		#expect(Basis.FileStatus(at: "/<missing>", followLink: true) == nil)
		
		try sandbox(name: #function) { directory in
			try directory.createDirectory("foo")
			try directory.createSymlink("link", of: "foo")
			
			check(
				at: directory[path: "link"],
				type: .directory, symlink: true
			)
		}
	}
	
	
	@Test
	func 存在しないパスの状態(
	) throws {
		try sandbox(name: #function) { directory in
			let missing: FilePath = directory[path: "missing"]

			#expect(missing.status == nil)
			#expect(missing.file.status == nil)
			#expect(missing.file.size == nil)
			#expect(missing.directory.modificationTime == nil)

			#expect(missing.fileExisting == nil)
			#expect(missing.directoryExisting == nil)

			#expect(missing.file.exists == false)
			#expect(missing.directory.exists == false)

			// リンク先が存在しないシンボリックリンク
			try directory.createSymlink("dangling", of: "missing")

			check(
				at: directory[path: "dangling"],
				type: nil, symlink: true
			)

			// リンクをたどらない場合はリンクそのもの
			#expect(Basis.FileStatus(at: directory[path: "dangling"], followLink: false)?.type == .link)

			// POSIX.copy はリンクをリンクとして複製する
			try POSIX.copy(
				at: directory[path: "dangling"].expanded,
				to: directory[path: "copied"].expanded,
			)

			#expect(try POSIX.readlink(at: directory[path: "copied"].expanded) == "missing")
		}
	}
	
	
	@Test
	func createSymbolicLink(
	) throws {
		try sandbox(name: #function) { directory in
			let path = fixtureDirectory.path
			
			//- abosolute
			
			try directory[file: "abosolute"].createSymlink(of: path)
			
			#expect(
				directory[file: "abosolute"].link
				==
				path.asString
			)
			#expect(
				directory[file: "abosolute"].linkTarget?.asString
				==
				path.asString + "/"
			)
			
			//- relative
			
			try directory[file: "relative"].createSymlink(of: "..")
			
			#expect(
				directory[file: "relative"].link
				==
				".."
			)
			#expect(
				directory[file: "relative"].linkTarget
				==
				directory.parent.path.realized
			)
			
			//- missing
			
			try directory[file: "missing"].createSymlink(of: "foo/bar")
			
			#expect(
				directory[file: "missing"].link
				==
				"foo/bar"
			)
			#expect(
				directory[file: "missing"].linkTarget?.asString
				==
				nil
			)
			
		}
	}
	
	
	@Test
	func readText() throws {
		let path: FilePath = fixtureDirectory[file: "hello"].path
		let result: Binary = try path.file.binary
		
		#expect(
			Int64(result.count)
			==
			path.file.status?.size
		)
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
