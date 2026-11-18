#if canImport(Darwin) || canImport(Glibc)
@testable import Basis
import Libc


@Test
func subprocess_searches_child_path_relative_to_working_directory() throws {
	try Directory.withTemporary { directory in
		let path: FilePath = directory.path

		let executable = path["bin/snapshot-tool"].file
		try executable.save("#!/bin/sh\nprintf '%s\\n' \"$BASIS_VALUE\"\n/bin/pwd -P\n")
		try executable.setPermissions(0o700)

		// $を含む実ディレクトリも、親プロセスの環境変数で再展開しない。
		let workingDirectory = path.appending("$BASIS_LITERAL")
		try POSIX.createDirectory(at: workingDirectory.asString)

		let currentDirectory = POSIX.getcwd()
		let process = try Subprocess.execute(
			file: "snapshot-tool",
			workingDirectory: workingDirectory,
			environment: ["PATH": "../bin", "BASIS_VALUE": "captured"],
		)
		process.closeInput()
		let result = try process.wait(timeout: 3)

		#expect(result.status.exitCode == 0)
		#expect(result.output.asString.split(separator: "\n").map(String.init) == ["captured", try POSIX.realpath(workingDirectory.asString)])
		#expect(POSIX.getcwd() == currentDirectory)
	}
}


@Test
func subprocess_resolves_relative_program_against_working_directory() throws {
	try Directory.withTemporary { directory in
		let executable = directory[file: "bin/tool"]
		try executable.save("#!/bin/sh\nprintf ok\n")
		try executable.setPermissions(0o700)

		let process = try Subprocess.execute(
			["bin/tool"],
			workingDirectory: directory.path,
			environment: [:],
		)
		process.closeInput()

		#expect(try process.wait(timeout: 3).output.asString == "ok")
	}
}


@Test
func subprocess_search_uses_child_path() throws {
	try Directory.withTemporary { directory in
		let executable = directory[file: "tool"]
		try executable.save("#!/bin/sh\nexit 0\n")

		func search(_ file: String, path: String?) -> FilePath? {
			Subprocess.searchExecutable(
				file,
				workingDirectory: directory.path,
				environment: path.map { ["PATH": $0] } ?? [:],
			)
		}

		// 実行できないファイルは見つからない
		#expect(search("tool", path: "") == nil)

		try executable.setPermissions(0o700)

		// 空の項目は作業ディレクトリ
		#expect(search("tool", path: "") == executable.path)
		#expect(search("tool", path: "/usr/bin:") == executable.path)
		#expect(search("tool", path: "/usr/bin") == nil)
		#expect(search("tool", path: nil) == nil)
		#expect(search("missing", path: "") == nil)

		// /を含む名前は作業ディレクトリを基準にする
		#expect(search("./tool", path: nil)?.realpath == executable.path.realpath)
	}
}


@Test
func subprocess_environment_shell_and_argument_overloads() throws {
	let environment: [String : String] = ["VALUE": "child"]

	let shell = try Subprocess.execute(command: "printf '%s' \"$VALUE\"", workingDirectory: "/", environment: environment)
	shell.closeInput()
	let shellResult = try shell.wait(timeout: 3)
	#expect(shellResult.status.exitCode == 0)
	#expect(shellResult.output.asString == "child")

	let arguments = try Subprocess.execute(["/bin/sh", "-c", "printf '%s' \"$VALUE\""], environment: environment)
	arguments.closeInput()
	let argumentResult = try arguments.wait(timeout: 3)
	#expect(argumentResult.status.exitCode == 0)
	#expect(argumentResult.output.asString == "child")

	// 子プロセスのPATHにないプログラムは見つからない
	#expect(throws: GeneralError.self) {
		try Subprocess.execute(file: "pwd", environment: environment)
	}
	#expect(throws: GeneralError.self) {
		try Subprocess.execute([], environment: environment)
	}
}
#endif
