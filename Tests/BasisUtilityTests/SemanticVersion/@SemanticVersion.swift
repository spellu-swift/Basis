@testable import BasisUtility


struct SemanticVersionTests {

	@Test(arguments: [
		"0.0.0", "1.2.3", "1.2.3-alpha.0+001", "1.2.3-x-y-z.--+build.01",
		"999999999999999999999999999999.0.1",
	])
	func 正しい形式を全情報を保って往復する(_ text: String) throws {
		let version: SemanticVersion = try .parse(text)
		#expect(version.description == text)
	}

	@Test(arguments: [
		"", "1", "1.2", "1.2.3.4", "01.2.3", "1.02.3", "1.2.03", "-1.2.3",
		"v1.2.3", " 1.2.3", "1.2.3\n", "1.2.3-", "1.2.3+", "1.2.3-a..b",
		"1.2.3-01", "1.2.3-a_1", "1.2.3+aa..bb", "1.2.3+a+b", "1.2.3-日本語",
		"１.2.3",
	])
	func 不正な形式を拒否する(_ text: String) {
		#expect(throws: GeneralError.self) { try SemanticVersion.parse(text) }
	}

	@Test func コンポーネントの構築でも検証する() throws {
		let version: SemanticVersion = try .init(
			major: 1,
			minor: 2,
			patch: 3,
			prerelease: ["alpha", "1"],
			build: "001"
		)
		#expect(version.major == 1)
		#expect(version.minor == 2)
		#expect(version.patch == 3)
		#expect(version.prerelease == ["alpha", "1"])
		#expect(version.build == "001")
		#expect(version.description == "1.2.3-alpha.1+001")
		#expect(throws: GeneralError.self) {
			try SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: [""])
		}
		#expect(throws: GeneralError.self) {
			try SemanticVersion(
				major: 1,
				minor: 2,
				patch: 3,
				prerelease: ["01"]
			)
		}
		#expect(throws: GeneralError.self) {
			try SemanticVersion(major: 1, minor: 2, patch: 3, build: "")
		}

	}

	@Test func 数値は整数上限を超えて比較と加算ができる() throws {
		let value: SemanticVersion.Number = try .init(
			"999999999999999999999999999999"
		)
		#expect(
			value.incremented.description == "1000000000000000000000000000000"
		)
		#expect(value < value.incremented)
		#expect(
			SemanticVersion.Number(UInt.max).description == String(UInt.max)
		)
		#expect(SemanticVersion.Number(integerLiteral: 0).incremented == 1)
		for text in ["", "01", "-1", "+1", "1a", "１"] {
			#expect(throws: GeneralError.self) {
				try SemanticVersion.Number(text)
			}
		}
	}

	@Test func 加算では下位をリセットし付加情報を除去する() throws {
		let value: SemanticVersion = try .parse("1.2.3-alpha+build")
		#expect(value.majorIncremented.description == "2.0.0")
		#expect(value.minorIncremented.description == "1.3.0")
		#expect(value.patchIncremented.description == "1.2.4")
	}

	@Test
	func ハッシュ値の一致を確認する() throws {
		let a = try SemanticVersion(major: 1, minor: 2, patch: 3, build: "a")
		let b = try SemanticVersion(major: 1, minor: 2, patch: 3, build: "b")

		#expect(a == b)
		#expect(a.hashValue == b.hashValue)
		#expect(Set([a, b]).count == 1)
		#expect([a: "found"][b] == "found")
	}

}
