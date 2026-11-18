import Basis


@Suite struct FilePermissionsTests {

	@Test
	func 対象ごとの指定は8進数と一致する() {
		#expect(FilePermissions(owner: .readWrite, group: .read, other: .read) == 0o644)
		#expect(FilePermissions(owner: .all, group: .readExecute, other: .readExecute) == 0o755)
		#expect(FilePermissions(owner: .readWrite) == 0o600)

		let permissions: FilePermissions = 0o751

		#expect(permissions.owner == .all)
		#expect(permissions.group == .readExecute)
		#expect(permissions.other == .execute)
	}


	@Test
	func 対象ごとに権限を持っているか調べる() {
		let permissions: FilePermissions = 0o754

		#expect(permissions.containsAll(owner: .execute))
		#expect(permissions.containsAll(owner: .all, group: .readExecute, other: .read))
		#expect(permissions.containsAll(group: .execute))
		#expect(permissions.containsAll(other: .execute) == false)
		#expect(permissions.containsAll(group: .write) == false)

		// 1つでも欠けていれば false
		#expect(permissions.containsAll(owner: .execute, group: .execute, other: .execute) == false)

		// 何も指定しなければ true
		#expect(permissions.containsAll())
	}


	@Test
	func 対象ごとに権限をどれか持っているか調べる() {
		let permissions: FilePermissions = 0o640

		#expect(permissions.containsAny(owner: .execute, group: .read))
		#expect(permissions.containsAny(owner: .execute, group: .execute, other: .execute) == false)
		#expect((0o744 as FilePermissions).containsAny(owner: .execute, group: .execute, other: .execute))
		#expect((0o001 as FilePermissions).containsAny(owner: .execute, group: .execute, other: .execute))

		// 何も指定しなければ false
		#expect(permissions.containsAny() == false)
	}


	@Test
	func 権限の範囲外のビットは捨てる() {
		#expect(FilePermissions(rawValue: 0o100644) == 0o644)
	}


	@Test(arguments: [
		(0o644 as FilePermissions, "rw-r--r--"),
		(0o755, "rwxr-xr-x"),
		(0o000, "---------"),
		(0o4755, "rwsr-xr-x"),
		(0o4644, "rwSr--r--"),
		(0o2755, "rwxr-sr-x"),
		(0o1777, "rwxrwxrwt"),
		(0o1776, "rwxrwxrwT"),
	])
	func 文字列と相互に変換できる(
		permissions: FilePermissions,
		string: String,
	) {
		#expect(permissions.description == string)
		#expect(FilePermissions(string) == permissions)
	}


	@Test(arguments: [
		"",
		"rw-r--r",
		"rw-r--r--x",
		"wr-r--r--",
		"rw-r--r-s",
		"rwtr--r--",
	])
	func 不正な文字列はnilになる(
		string: String,
	) {
		#expect(FilePermissions(string) == nil)
	}


	@Test
	func 権限を変更する() throws {
		try sandbox(name: #function) { directory in
			let file: File = directory[file: "script"]

			try file.save("echo")
			try file.setPermissions(0o600)

			#expect(file.permissions == 0o600)

			try file.path.updatePermissions { $0.insert(.ownerExecute) }

			#expect(file.permissions == 0o700)

			let sub: Directory = directory["sub"]

			try sub.createDirectory()
			try sub.setPermissions(0o750)

			#expect(sub.permissions == 0o750)
		}
	}


	@Test
	func 存在しないパスの権限() throws {
		try sandbox(name: #function) { directory in
			let missing: FilePath = directory[path: "missing"]

			#expect(missing.file.permissions == nil)
			#expect(throws: POSIXError.self) { try missing.setPermissions(0o644) }
			#expect(throws: POSIXError.self) { try missing.updatePermissions { _ in } }
		}
	}

}


@Suite struct FileAccessTests {

	@Test
	func 権限に応じて読み書き実行できるか調べる() throws {
		try sandbox(name: #function) { directory in
			let file: File = directory[file: "file"]

			try file.save("echo")

			try file.setPermissions(0o600)
			#expect(file.isReadable)
			#expect(file.isWritable)
			#expect(file.isExecutable == false)
			#expect(file.readonly == false)

			#expect(file.access(.readWrite))
			#expect(file.path.access(.readWrite))
			#expect(file.access(.all) == false)

			try file.setPermissions(0o400)
			#expect(file.isReadable)
			#expect(file.isWritable == false)
			#expect(file.readonly)

			try file.setPermissions(0o700)
			#expect(file.isExecutable)

			try file.setPermissions(0o000)
			#expect(file.isReadable == false)

			try file.setPermissions(0o600)
		}
	}


	@Test
	func ディレクトリを調べる() throws {
		try sandbox(name: #function) { directory in
			#expect(directory.isReadable)
			#expect(directory.isWritable)
			#expect(directory.isExecutable)
			#expect(directory.access([.read, .write, .execute]))
			#expect(directory.path.access(.all))
		}
	}


	@Test
	func 存在しないパスはfalse() throws {
		try sandbox(name: #function) { directory in
			let missing: FilePath = directory[path: "missing"]

			#expect(missing.file.isReadable == false)
			#expect(missing.directory.isWritable == false)
			#expect(POSIX.access(missing.asString, []) == false)
			#expect(POSIX.access(directory.path.asString, []))

			#expect(missing.access([]) == false)
			#expect(missing.file.access(.read) == false)
			#expect(missing.directory.access(.read) == false)
		}
	}

}
