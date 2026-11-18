import Libc


extension Directory {

	/// 空の一時ディレクトリを排他的に作成し、処理終了時に中身ごと削除する。
	/// 保存先の省略時はシステムの一時ディレクトリを使う。
	/// 後片付けの失敗は、処理本体の結果やエラーを置き換えない。
	public static func withTemporary<Result>(
		prefix: String = "Basis",
		in directory: Directory? = nil,
		perform: (Directory) throws -> Result,
	) throws -> Result {
		while true {
			let path = TemporaryPath.make(prefix: prefix, in: directory)
			let result = File.retryInterrupted { mkdir(path.asString, FilePermissions(owner: .all).mode) }

			if result == -1 {
				let error = errno
				if error == EEXIST { continue }
				throw POSIXError.system(error)
			}

			defer {
				try? POSIX.deleteDirectory(at: path.asString, recursive: true, force: true)
			}

			return try perform(.init(at: path))
		}
	}
}
