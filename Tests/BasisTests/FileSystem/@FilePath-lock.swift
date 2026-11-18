@testable import Basis
import Libc


private enum LockTestError : Error {
	case failed
}


/// テストの中で、別のプロセスに見立ててロックを持つ。
private func holdLock(
	_ path: FilePath,
) -> Int32 {
	let handle: Int32 = open(
		path.asString,
		O_RDWR | O_CREAT | O_CLOEXEC,
		0o600,
	)
	#expect(handle >= 0)
	#expect(flock(handle, LOCK_EX) == 0)
	return handle
}


// MARK: - 既定のロックファイル


@Test
func 既定のロックファイルは対象の隣の隠しファイル() throws {
	#expect(try FilePath("/a/b/c.yaml").defaultLockPath() == FilePath("/a/b/.c.yaml.lock"))
	#expect(try FilePath("/c.yaml").defaultLockPath() == FilePath("/.c.yaml.lock"))
	#expect(try FilePath("c.yaml").defaultLockPath() == FilePath(".c.yaml.lock"))
	#expect(try FilePath("a/c.yaml").defaultLockPath() == FilePath("a/.c.yaml.lock"))
}


@Test
func 既定のロックファイルはディレクトリの末尾のスラッシュを除く() throws {
	#expect(try FilePath("/a/Foo.app/").defaultLockPath() == FilePath("/a/.Foo.app.lock"))
}


@Test
func 既定のロックファイルは隠しファイルの対象にもドットを付ける() throws {
	#expect(try FilePath("/a/.hidden").defaultLockPath() == FilePath("/a/..hidden.lock"))
}


@Test
func 既定のロックファイルは名前のない対象ではエラー() throws {
	#expect(throws: POSIXError.self) {
		try FilePath("/").defaultLockPath()
	}
	#expect(throws: POSIXError.self) {
		try FilePath("/a/..").defaultLockPath()
	}
}


// MARK: - 取る・外す


@Test
func withLockは処理の間だけロックファイルを置き結果を返す() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]

		let result: Int = try target.withLock {
			#expect(lockFile.file.exists)
			#expect(!target.file.exists)
			return 42
		}

		#expect(result == 42)
		#expect(!lockFile.file.exists)
		#expect(!target.file.exists)
	}
}


@Test
func withLockは処理がエラーでもロックを外しロックファイルを削除する() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]

		#expect(throws: LockTestError.self) {
			try target.withLock {
				throw LockTestError.failed
			}
		}

		#expect(!lockFile.file.exists)

		// もう一度取れる
		try target.withLock {}
	}
}


@Test
func withLockはロックファイルを明示できる() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path["custom.lock"]

		try target.withLock(lock: lockFile) {
			#expect(lockFile.file.exists)
			#expect(!directory.path[".state.yaml.lock"].file.exists)
		}

		#expect(!lockFile.file.exists)
	}
}


@Test
func Fileのwithlockは対象のパスで排他する() throws {
	try sandbox(name: #function) { directory in
		let file: File = directory.path["state.yaml"].file
		try file.save("state")

		try file.withLock {
			#expect(directory.path[".state.yaml.lock"].file.exists)
		}

		#expect(!directory.path[".state.yaml.lock"].file.exists)
		#expect(try file.load().asString == "state")
	}
}


@Test
func Directoryのwithlockは対象の隣にロックファイルを置く() throws {
	try sandbox(name: #function) { directory in
		let app: Directory = directory.path["Foo.app"].directory

		try app.withLock {
			#expect(directory.path[".Foo.app.lock"].file.exists)
			#expect(!app.exists)
		}

		#expect(!directory.path[".Foo.app.lock"].file.exists)
	}
}


@Test
func withLockは残っていた古いロックファイルでも取れて削除する() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]

		// 異常終了したプロセスの名残
		try lockFile.file.save("")

		try target.withLock {}

		#expect(!lockFile.file.exists)
	}
}


// MARK: - 競合


@Test
func withLockはほかが持っているとlockedを投げる() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]

		let handle: Int32 = holdLock(lockFile)
		defer { close(handle) }

		var ran: Bool = false

		#expect(throws: FileSystemError.locked(lockFile.file)) {
			try target.withLock {
				ran = true
			}
		}

		#expect(!ran)
		// ほかの持ち主のロックファイルは削除しない
		#expect(lockFile.file.exists)
	}
}


@Test
func withLockは入れ子に取れない() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]

		try target.withLock {
			#expect(throws: FileSystemError.locked(lockFile.file)) {
				try target.withLock {}
			}
			// 外側のロックファイルは残っている
			#expect(lockFile.file.exists)
		}

		#expect(!lockFile.file.exists)
	}
}


@Test
func withLockはwaitなら外れるまで待つ() async throws {
	let directory: Directory
	= Backbone.temporaryDirectory["lock-wait-\(UUID.new)"].directory
	try directory.createDirectory()
	defer { try? directory.deleteDirectory(recursive: true) }

	let target: FilePath = directory.path["state.yaml"]
	let lockFile: FilePath = directory.path[".state.yaml.lock"]
	let released: Barrier<Bool> = .init(false)

	let handle: Int32 = holdLock(lockFile)

	let waiter: Task<Bool, any Error> = Task.detached {
		try target.withLock(wait: true) {
			released.atomic { $0 }
		}
	}

	try await Task.sleep(for: .milliseconds(200))
	released.atomic { $0 = true }
	close(handle)

	// 待っていた側は、外れた後に処理を行った
	#expect(try await waiter.value)
	#expect(!lockFile.file.exists)
}


@Test
func withLockは削除されたロックファイルのロックを取ったらやり直す() async throws {
	let directory: Directory
	= Backbone.temporaryDirectory["lock-retry-\(UUID.new)"].directory
	try directory.createDirectory()
	defer { try? directory.deleteDirectory(recursive: true) }

	let target: FilePath = directory.path["state.yaml"]
	let lockFile: FilePath = directory.path[".state.yaml.lock"]
	let released: Barrier<Bool> = .init(false)

	// 前の持ち主が、ロックファイル（A）を持っている
	let first: Int32 = holdLock(lockFile)

	let waiter: Task<Bool, any Error> = Task.detached {
		try target.withLock(wait: true) {
			released.atomic { $0 }
		}
	}

	// 待つ側が A を開いて、ロックを待つまで待つ
	try await Task.sleep(for: .milliseconds(200))

	// 前の持ち主が A を削除して外す。その直後に、別の持ち主が新しいファイル（B）を取る
	#expect(unlink(lockFile.asString) == 0)
	let second: Int32 = holdLock(lockFile)
	close(first)

	// 待つ側は A のロックを取るが、削除済みと気づいて B を待ち直す
	try await Task.sleep(for: .milliseconds(200))
	released.atomic { $0 = true }
	close(second)

	#expect(try await waiter.value)
	#expect(!lockFile.file.exists)
}


// MARK: - 不正なロックファイル


@Test
func withLockはロックファイルがディレクトリならinvalidType() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]
		try lockFile.directory.createDirectory()

		#expect(throws: FileSystemError.invalidType(lockFile.file)) {
			try target.withLock {}
		}

		#expect(lockFile.directory.exists)
	}
}


@Test
func withLockはロックファイルがシンボリックリンクならinvalidType() throws {
	try sandbox(name: #function) { directory in
		let target: FilePath = directory.path["state.yaml"]
		let lockFile: FilePath = directory.path[".state.yaml.lock"]
		let other: FilePath = directory.path["other"]
		try other.file.save("other")
		#expect(symlink(other.asString, lockFile.asString) == 0)

		#expect(throws: FileSystemError.invalidType(lockFile.file)) {
			try target.withLock {}
		}

		#expect(try other.file.load().asString == "other")
		#expect(FileStatus(at: lockFile.asString, followLink: false) != nil)
	}
}
