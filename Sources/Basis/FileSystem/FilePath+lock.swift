import Libc


extension FilePath {

	/// このパスを対象に、処理の間だけ、ほかのプロセスと排他する。
	///
	/// 対象はファイルでもディレクトリでもよく、まだ存在しなくてもよい。
	/// 排他には`flock`の排他ロックを使う。
	///
	/// - `lock`を省くと、対象と同じディレクトリの`.<対象の名前>.lock`を使う。
	/// - ロックファイルがなければ作り、処理の後で削除する。
	/// - `wait`がfalseのとき、ほかのプロセスがロックを持っていれば、
	///   ``FileSystemError/locked(_:)``を投げる。trueなら取れるまで待つ。
	/// - ロックファイルが通常のファイルでなければ、
	///   ``FileSystemError/invalidType(_:)``を投げる。
	/// - 同じプロセスの中でも、同じロックを入れ子に取ることはできない。
	///   入れ子にすると、`wait`がfalseなら`locked`を投げ、trueなら止まる。
	/// - プロセスが異常終了しても、ロックは外れる。
	///   ロックファイルは残るが、次に使い終わった者が削除する。
	///
	/// ```swift
	/// try FilePath("Package.version.yaml").withLock {
	/// 	// ここだけが排他される
	/// }
	/// ```
	public func withLock<Result>(
		lock: FilePath? = nil,
		wait: Bool = false,
		perform: () throws -> Result,
	) throws -> Result {
		// 処理の中でカレントディレクトリが変わっても、同じファイルを削除する
		let lockPath: String
		= try FilePath(
			(lock ?? defaultLockPath()).expanded,
		).absoluted.asString

		let handle: Int32
		= try FileLock.acquire(
			at: lockPath,
			wait: wait,
		)

		defer {
			// ロックを持ったまま削除してから閉じる。
			// 先に閉じると、削除の前に別のプロセスがロックを取り、
			// そのプロセスのロックファイルを削除してしまう。
			_ = unlink(lockPath)
			close(handle)
		}

		return try perform()
	}

	/// 既定のロックファイル。対象と同じディレクトリの`.<対象の名前>.lock`。
	func defaultLockPath(
	) throws -> FilePath {
		let (directory, name): (String, Substring?)
		= FilePath.splitPath(expanded)

		guard
			let name,
			name != ".",
			name != ".."
		else { throw POSIXError.system(EINVAL) }

		let fileName: String
		= ".\(name).lock"

		return if directory.isEmpty {
			FilePath(fileName)
		}
		else if directory.hasSuffix("/") {
			FilePath(directory + fileName)
		}
		else {
			FilePath(directory + "/" + fileName)
		}
	}

}


extension File {

	/// このファイルを対象に、処理の間だけ、ほかのプロセスと排他する。
	/// ``FilePath/withLock(lock:wait:perform:)``と同じ。
	@inlinable
	public func withLock<Result>(
		lock: FilePath? = nil,
		wait: Bool = false,
		perform: () throws -> Result,
	) throws -> Result {
		try path.withLock(
			lock: lock,
			wait: wait,
			perform: perform,
		)
	}

}


extension Directory {

	/// このディレクトリを対象に、処理の間だけ、ほかのプロセスと排他する。
	/// ``FilePath/withLock(lock:wait:perform:)``と同じ。
	@inlinable
	public func withLock<Result>(
		lock: FilePath? = nil,
		wait: Bool = false,
		perform: () throws -> Result,
	) throws -> Result {
		try path.withLock(
			lock: lock,
			wait: wait,
			perform: perform,
		)
	}

}


private enum FileLock {

	/// ロックファイルを開いて排他ロックを取り、そのファイル記述子を返す。
	///
	/// 取ったロックが、削除されたロックファイルのものだった場合は、やり直す。
	/// 前の持ち主が削除する前に開いていたファイルを、
	/// 削除の後でロックした場合に起きる。
	static func acquire(
		at path: String,
		wait: Bool,
	) throws -> Int32 {
		let file: File
		= .init(at: FilePath(path))

		while true {
			let handle: Int32 = File.retryInterrupted {
				open(
					path,
					O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC,
					FilePermissions(owner: .readWrite).mode,
				)
			}

			if handle == -1 {
				let error: Int32 = errno

				switch error {
					case ELOOP, EISDIR:
						// シンボリックリンク、ディレクトリ
						throw FileSystemError.invalidType(file)
					default:
						throw POSIXError.system(error)
				}
			}

			var opened: stat = .init()

			guard
				fstat(handle, &opened) == 0
			else {
				let error: Int32 = errno
				close(handle)
				throw POSIXError.system(error)
			}

			guard
				opened.st_mode & S_IFMT == S_IFREG
			else {
				close(handle)
				throw FileSystemError.invalidType(file)
			}

			let operation: Int32
			= wait ? LOCK_EX : LOCK_EX | LOCK_NB

			if File.retryInterrupted({ flock(handle, operation) }) == -1 {
				let error: Int32 = errno
				close(handle)

				if error == EWOULDBLOCK {
					throw FileSystemError.locked(file)
				}

				throw POSIXError.system(error)
			}

			var current: stat = .init()

			if lstat(path, &current) == -1 {
				let error: Int32 = errno
				close(handle)

				// 前の持ち主が削除した
				if error == ENOENT { continue }

				throw POSIXError.system(error)
			}

			if
				current.st_dev != opened.st_dev
				|| current.st_ino != opened.st_ino
			{
				// 前の持ち主が削除した後、別のプロセスが作り直した
				close(handle)
				continue
			}

			return handle
		}
	}

}
