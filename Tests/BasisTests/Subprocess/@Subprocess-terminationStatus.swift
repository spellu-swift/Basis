#if canImport(Darwin) || canImport(Glibc)
import Libc
@testable import Basis


struct SubprocessTerminationStatusTests {

	@Test func 終了コードとシグナルを混同しない() throws {
		let success: Subprocess.TerminationStatus = .exited(code: 0)
		#expect(success.isSuccess)
		#expect(success.exitCode == 0)
		#expect(success.signal == nil)
		#expect(success.description == "exited(code: 0)")
		let exit: Subprocess.TerminationStatus = .exited(code: 143)
		let signal: Subprocess.TerminationStatus = .signaled(
			signal: SIGTERM
		)
		#expect(exit != signal)
		#expect(!exit.isSuccess)
		#expect(exit.exitCode == 143)
		#expect(exit.signal == nil)
		#expect(!signal.isSuccess)
		#expect(signal.exitCode == nil)
		#expect(signal.signal == SIGTERM)
		#expect(signal.description == "signaled(signal: 15)")
	}

	@Test func wait状態を判定しコアダンプビットを番号に含めない() throws {
		#expect(
			try Subprocess.TerminationStatus(waitStatus: 0)
				== .exited(code: 0)
		)
		#expect(
			try Subprocess.TerminationStatus(waitStatus: 255 << 8)
				== .exited(code: 255)
		)
		#expect(
			try Subprocess.TerminationStatus(waitStatus: SIGTERM)
				== .signaled(signal: SIGTERM)
		)
		#expect(
			try Subprocess.TerminationStatus(
				waitStatus: SIGTERM | 0x80
			) == .signaled(signal: SIGTERM)
		)
		#expect(throws: GeneralError.self) {
			try Subprocess.TerminationStatus(waitStatus: 0x7f)
		}
	}

	@Test func 結果の変換はシグナル終了もエラーにする() throws {
		let result: Subprocess.Result = .init(
			output: "ok".asBinary,
			error: "error".asBinary,
			status: .exited(code: 0)
		)
		#expect(try result.asString == "ok")
		#expect(try result.asBinary.asString == "ok")
		#expect(result.map { $0.status.isSuccess })
		for status: Subprocess.TerminationStatus in [
			.exited(code: 1), .signaled(signal: SIGKILL),
		] {
			let failure: Subprocess.Result = .init(
				output: "partial".asBinary,
				error: "error".asBinary,
				status: status
			)
			#expect(throws: GeneralError.self) {
				try failure.asString
			}
			#expect(throws: GeneralError.self) {
				try failure.asBinary
			}
			#expect(failure.output.asString == "partial")
		}
	}
	@Test func waitpidが割り込まれたら再試行し他のエラーは送出する() throws {
		var attempts: Int = 0
		let status: Subprocess.TerminationStatus =
			try Subprocess.waitForProcess(pid: 123) { pid, status, options in
				#expect(pid == 123)
				#expect(options == 0)
				attempts += 1
				if attempts == 1 {
					errno = EINTR
					return -1
				}
				status.pointee = 7 << 8
				return pid
			}
		#expect(attempts == 2)
		#expect(status == .exited(code: 7))
		#expect(throws: POSIXError.system(ECHILD)) {
			try Subprocess.waitForProcess(pid: 123) { _, _, _ in
				errno = ECHILD
				return -1
			}
		}
	}

}
#endif
