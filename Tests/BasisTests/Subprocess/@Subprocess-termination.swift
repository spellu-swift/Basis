#if canImport(Darwin) || canImport(Glibc)
import Libc
@testable import Basis


struct SubprocessTerminationTests {

	@Test(arguments: [SIGTERM, SIGKILL])
	func シグナル終了でも出力を回収し成功扱いしない(_ signal: Int32) async throws {
		let process: Subprocess = try .execute(
			file: "/bin/sh",
			arguments: [
				"-c",
				"printf output; printf error >&2; kill -\(signal) $$",
			]
		)
		process.closeInput()
		let result: Subprocess.Result = try process.wait()
		#expect(result.status == .signaled(signal: signal))
		#expect(result.output.asString == "output")
		#expect(result.error.asString == "error")
		#expect(throws: GeneralError.self) { try result.asString }
	}

	@Test func 終了コード143はSIGTERMと区別される() async throws {
		let process: Subprocess = try .execute(
			file: "/bin/sh",
			arguments: ["-c", "exit 143"]
		)
		process.closeInput()
		#expect(try process.wait().status == .exited(code: 143))
	}

	@Test(arguments: ["exit 0", "exit 7", "kill -TERM $$"])
	func ストリームも終了理由を失わない(_ command: String) async throws {
		let process: Subprocess = try .execute(
			file: "/bin/sh",
			arguments: [
				"-c",
				"printf output; printf error >&2; " + command,
			]
		)
		process.closeInput()
		var output: [UInt8] = []
		var error: [UInt8] = []
		var statuses: [Subprocess.TerminationStatus] = []
		for try await event in process.stream {
			switch event {
			case .output(let bytes): output += bytes
			case .error(let bytes): error += bytes
			case .terminated(let status): statuses.append(status)
			}
		}
		#expect(output.asString == "output")
		#expect(error.asString == "error")
		let expected: Subprocess.TerminationStatus =
			command == "exit 0"
			? .exited(code: 0)
			: command == "exit 7"
				? .exited(code: 7) : .signaled(signal: SIGTERM)
		#expect(statuses == [expected])
	}

	@Test func 待機失敗を偽の終了コードへ変換しない() async throws {
		var output: [Int32] = [-1, -1]
		var error: [Int32] = [-1, -1]
		#expect(pipe(&output) == 0)
		#expect(pipe(&error) == 0)
		close(output[1])
		close(error[1])
		let process: Subprocess = .init(
			pid: .max,
			inFd: -1,
			outFd: output[0],
			errFd: error[0]
		)
		await #expect(throws: POSIXError.system(ECHILD)) {
			for try await event in process.stream {
				if case .terminated = event {
					Issue.record("待機失敗を終了扱いにした")
				}
			}
		}
	}
	@Test func 別プロセスの入力パイプを継承してEOFを妨げない() async throws {
		let first: Subprocess = try .execute(file: "/bin/cat")
		let second: Subprocess = try .execute(file: "/bin/cat")
		_ = first.input("first")
		let result: Subprocess.Result? = try? first.wait(timeout: 1)
		_ = second.input("second")
		let other: Subprocess.Result = try second.wait(timeout: 1)
		#expect(result?.status == .exited(code: 0))
		#expect(result?.output.asString == "first")
		#expect(other.output.asString == "second")
	}

	@Test func 親で開いたディスクリプタを子へ渡さない() throws {
		var fds: [Int32] = [-1, -1]
		#expect(pipe(&fds) == 0)
		defer {
			close(fds[0])
			close(fds[1])
		}

		let process: Subprocess = try .execute(
			command: "(: <&\(fds[0])) 2>/dev/null && printf open || printf closed",
		)
		process.closeInput()

		#expect(try process.wait(timeout: 3).output.asString == "closed")
	}

	@Test func パイプ容量を超える標準出力と標準エラーを両方回収する() async throws {
		let process: Subprocess = try .execute(
			file: "/bin/sh",
			arguments: [
				"-c",
				"i=0; while [ $i -lt 10000 ]; do printf 1234567890; printf abcdefghij >&2; i=$((i+1)); done",
			]
		)
		process.closeInput()
		let result: Subprocess.Result = try process.wait(timeout: 5)
		#expect(result.status.isSuccess)
		#expect(
			result.output.asString
				== String(repeating: "1234567890", count: 10000)
		)
		#expect(
			result.error.asString
				== String(repeating: "abcdefghij", count: 10000)
		)
	}

}
#endif
