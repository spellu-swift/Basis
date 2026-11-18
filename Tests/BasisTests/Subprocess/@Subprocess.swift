#if canImport(Darwin) || canImport(Glibc)
@testable import Basis
import Libc


struct SubprocessTests {
	
	@Test func execute_ls() throws {
		let currentDirectory: String = POSIX.getcwd()
		let workingDirectory: FilePath = fixtureDirectory.path

		_ = try Subprocess.execute(
			file: "/bin/pwd",
			workingDirectory: workingDirectory,
		)
		_ = try Subprocess.execute(
			file: "/bin/ls",
			arguments: ["-la"],
			workingDirectory: workingDirectory,
		)

		#expect(POSIX.getcwd() == currentDirectory)
	}

	@Test func execute_cat_file() async throws {
		let result: Subprocess.Result
		= try Subprocess
			.execute(["/bin/cat", fixtureDirectory[file: "hello"].path.asString])
			.wait()
		
		#expect(result.status.exitCode	== 0)
		#expect(result.output.asString == "Hello!\n")
	}
	
	@Test func execute_cat_stdin() async throws {
		let input: String = "foo bar"
		
		let result: Subprocess.Result
		= try Subprocess
			.execute(["/bin/cat"])
			.input(input)
			.wait()
		
		#expect(result.status.exitCode	== 0)
		#expect(result.output.count	== 7)
		#expect(result.error.count	== 0)
	}
	
	@Test func execute_cat_stdin_timedout() async throws {
		let input: String = "foo bar"
		
		let process: Subprocess
		= try Subprocess
			.execute(["/bin/cat"])
		
		process.write(input)
		
		#expect(throws: GeneralError.timedOut) {
			_ = try process.wait(
				timeout: 1.0,
			)
		}
	}
	
	@Test func execute_pwd_provideWorkingDirectory() async throws {
		let result: Subprocess.Result
		= try Subprocess
			.execute(
				file: "pwd",
				arguments: [],
				workingDirectory: "/",
			)
			.wait()
		
		#expect(result.status.exitCode == 0)
		#expect(result.output.asString.trimmed == "/")
	}

	@Test func execute_noSuchWorkingDirectory() async throws {
		#expect(throws: POSIXError.system(Libc.ENOENT)) {
			_ = try Subprocess
				.execute(
					file: "pwd",
					arguments: [],
					workingDirectory: "/foo/bar",
				)
				.wait()
		}
	}

	@Test(.timeLimit(.minutes(1)))
	func 出力を待ちながら入力を書ける() async throws {
		let process: Subprocess
		= try Subprocess
			.execute(["/bin/cat"])

		let events = process.stream

		process.write("foo ")
		process.write("bar")
		process.closeInput()

		var output: [UInt8] = []
		var status: Subprocess.TerminationStatus?

		for try await event in events {
			switch event {
				case .output(let bytes):
					output += bytes
				case .error:
					break
				case .terminated(let value):
					status = value
			}
		}

		#expect(output.asString == "foo bar")
		#expect(status == .exited(code: 0))
	}

	@Test func 入力を閉じた後の書き込みと二重のcloseは無視する() throws {
		let process: Subprocess
		= try Subprocess
			.execute(["/bin/cat"])

		process.closeInput()
		process.closeInput()
		process.write("ignored")

		let result: Subprocess.Result = try process.wait(timeout: 3)

		#expect(result.output.isEmpty)
		#expect(result.status == .exited(code: 0))
	}

	@Test func execute_asyncStream() async throws {
		let process: Subprocess
		= try Subprocess
			.execute(
				file: "ls",
				arguments: [],
				workingDirectory: "/",
			)
		
		for try await event in process.stream {
			switch event {
				case .output(let bytes):
					#expect(bytes.asString.count > 0)
				case .error(let bytes):
					#expect(bytes.asString.count > 0)
				case .terminated(let status):
					#expect(status == .exited(code: 0))
			}
		}
	}

}
#endif
