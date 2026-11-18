import Libc


extension File {

	/// 空の一時ファイルを排他的に作成し、処理終了時に削除する。
	/// 保存先の省略時はシステムの一時ディレクトリを使う。
	/// 後片付けの失敗は、処理本体の結果やエラーを置き換えない。
	public static func withTemporary<Result>(
		prefix: String = "Basis",
		suffix: String = "",
		in directory: Directory? = nil,
		perform: (File) throws -> Result,
	) throws -> Result {
		try withTemporaryHandle(prefix: prefix, suffix: suffix, in: directory) { file, _ in
			try perform(file)
		}
	}

	// アトミック保存でも、作成時のファイル記述子をそのまま使う。
	// 処理内で閉じた場合はhandleを-1にし、後片付けで二重に閉じない。
	static func withTemporaryHandle<Result>(
		prefix: String,
		suffix: String = "",
		in directory: Directory?,
		perform: (File, inout Int32) throws -> Result,
	) throws -> Result {
		while true {
			let path = TemporaryPath.make(prefix: prefix, suffix: suffix, in: directory)
			var handle = retryInterrupted {
				open(
					path.asString,
					O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC,
					FilePermissions(owner: .readWrite).mode,
				)
			}

			if handle == -1 {
				let error = errno
				if error == EEXIST { continue }
				throw POSIXError.system(error)
			}

			defer {
				if handle != -1 { close(handle) }
				_ = retryInterrupted { unlink(path.asString) }
			}

			return try perform(.init(at: path), &handle)
		}
	}

}
