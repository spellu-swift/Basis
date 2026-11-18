#if canImport(Darwin) || canImport(Glibc)

extension Subprocess {
	/// プロセスの終了理由。シグナル終了を終了コードへ変換しない。
	public enum TerminationStatus: Sendable, Equatable,
		CustomStringConvertible
	{
		case exited(code: Int32)
		case signaled(signal: Int32)

		public var isSuccess: Bool { self == .exited(code: 0) }
		public var exitCode: Int32? {
			if case .exited(let code) = self { return code }
			return nil
		}
		public var signal: Int32? {
			if case .signaled(let signal) = self {
				return signal
			}
			return nil
		}
		public var description: String {
			switch self {
			case .exited(let code): "exited(code: \(code))"
			case .signaled(let signal):
				"signaled(signal: \(signal))"
			}
		}

		init(waitStatus: Int32) throws {
			// DarwinとLinuxで共通のwait status。下位7ビットは終了シグナル、
			// 0x80はcore dumpフラグでありシグナル番号に含めない。
			let signal: Int32 = waitStatus & 0x7f
			if signal == 0 {
				self = .exited(
					code: (waitStatus >> 8) & 0xff
				)
			} else if signal != 0x7f {
				self = .signaled(signal: signal)
			} else {
				throw GeneralError.unexpectedValue(
					"プロセスが終了していません: \(waitStatus)"
				)
			}
		}
	}
}
#endif
