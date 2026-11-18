@testable import Basis
import Libc


@Suite struct BackboneEnvironmentTests {

	@Test func 起動時のプロセスの環境変数を持つ() {
		let environment = Backbone.environment

		#expect(environment["PATH"] != nil)
		#expect(environment["PATH"] == getenv("PATH").map { String(cString: $0) })
		#expect(environment["HOME"] == getenv("HOME").map { String(cString: $0) })
		#expect(environment.values["PATH"] == environment["PATH"])
	}


	@Test func 設定と削除がプロセスの環境変数にも反映される() {
		let environment = Backbone.environment
		let name: String = "BASIS_ENVIRONMENT_TEST_\(UUID.new.asString(.hex))"

		#expect(environment[name] == nil)

		environment.set(name: name, value: "first")
		#expect(environment.get(name: name) == "first")
		#expect(environment.values[name] == "first")
		#expect(getenv(name).map { String(cString: $0) } == "first")

		environment[name] = "second"
		#expect(environment[name] == "second")
		#expect(getenv(name).map { String(cString: $0) } == "second")

		environment[name] = nil
		#expect(environment[name] == nil)
		#expect(environment.values[name] == nil)
		#expect(getenv(name) == nil)
	}


#if os(macOS) || canImport(Glibc)
	@Test func 設定した値を子プロセスが引き継ぐ() throws {
		let environment = Backbone.environment
		let name: String = "BASIS_ENVIRONMENT_TEST_\(UUID.new.asString(.hex))"

		environment[name] = "inherited"
		defer { environment[name] = nil }

		let process = try Subprocess.execute(command: "printf '%s' \"$\(name)\"")
		process.closeInput()

		#expect(try process.wait(timeout: 3).output.asString == "inherited")
	}
#endif


	@Test func 不正な名前は設定しない() {
		let environment = Backbone.environment

		environment.set(name: "BASIS=INVALID", value: "value")

		#expect(environment["BASIS=INVALID"] == nil)
	}

}
