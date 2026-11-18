#if canImport(Darwin) || canImport(Glibc)

extension Subprocess {

	public struct Result: Sendable {
		public init(
			output: Binary,
			error: Binary,
			status: TerminationStatus,
		) {
			self.output = output
			self.error = error
			self.status = status
		}

		public var output: Binary
		public var error: Binary
		public var status: TerminationStatus
	}

}

extension Subprocess.Result {

	/// サブプロセスの実行が成功(status.isSuccess)した場合、出力文字列を返す。
	/// サブプロセスの実行が失敗(!status.isSuccess)した場合、例外を送出する。
	@inlinable
	public var asString: String {
		get throws {
			try asBinary.asString
		}
	}

	/// サブプロセスの実行が成功(status.isSuccess)した場合、出力バイナリを返す。
	/// サブプロセスの実行が失敗(!status.isSuccess)した場合、例外を送出する。
	@inlinable
	public var asBinary: Binary {
		get throws {
			guard
				status.isSuccess
			else {
				throw GeneralError.unexpectedValue(
					"Process [\(status)]: \(error.asString)"
				)
			}

			return output.asBinary
		}
	}

	/// 結果を変換する。
	@inlinable
	public func map<Result>(
		converter: (Self) throws -> Result
	) rethrows -> Result {
		try converter(self)
	}

}

#endif
