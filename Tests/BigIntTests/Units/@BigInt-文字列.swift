@testable import BigInt
import UnitTesting


@Suite struct BigInt文字列テスト {

	// MARK: 解析

	@Test func 十進数と十六進数の解析がPythonの結果と一致する() {
		for vector in representationVectors {
			let decimal: BigInt? = BigInt(vector.decimal)
			let hex: BigInt? = BigInt(vector.hex, radix: 16)

			#expect(decimal != nil)
			#expect(decimal == hex)
			#expect(decimal?.description == vector.decimal)
			#expect(decimal.map { String($0, radix: 16) } == vector.hex)
		}
	}

	@Test func 符号を解析できる() {
		#expect(BigInt("+42") == 42)
		#expect(BigInt("-42") == -42)
		#expect(BigInt("-0") == 0)
		#expect(BigInt("-0")?.description == "0")
	}

	@Test func 先頭の0を許す() {
		#expect(BigInt("0000000000000000000000000000042") == 42)
	}

	@Test func 基数と大文字小文字() {
		#expect(BigInt("ff", radix: 16) == 255)
		#expect(BigInt("FF", radix: 16) == 255)
		#expect(BigInt("zz", radix: 36) == 1295)
		#expect(BigInt("ZZ", radix: 36) == 1295)
		#expect(BigInt("101", radix: 2) == 5)
	}

	@Test func 不正な文字列はnil() {
		let invalids: [String] = [
			"",
			"+",
			"-",
			" 1",
			"1 ",
			"1_000",
			"0x10",
			"1.0",
			"1e3",
			"--1",
			"+-1",
			"１２３",
		]

		for text in invalids {
			#expect(BigInt(text) == nil, "\(text)")
		}
	}

	@Test func 基数で使えない数字はnil() {
		#expect(BigInt("2", radix: 2) == nil)
		#expect(BigInt("g", radix: 16) == nil)
		#expect(BigInt("9", radix: 8) == nil)
	}

	@Test func Substringから解析できる() {
		let text: String = "x12345678901234567890x"
		let slice: Substring = text.dropFirst().dropLast()

		#expect(BigInt(slice) == 12345678901234567890)
	}

	@Test func 長い桁数の往復() {
		let digits: String = String(repeating: "1234567890", count: 50)

		#expect(BigInt(digits)?.description == digits)
		#expect(BigInt("-" + digits)?.description == "-" + digits)
	}

	// MARK: 文字列化

	@Test func descriptionは十進数() {
		#expect(BigInt(0).description == "0")
		#expect(BigInt(-1).description == "-1")
		#expect(BigInt(UInt.max).description == "18446744073709551615")
		#expect(BigInt(10_000_000_000_000_000_000 as UInt64).description == "10000000000000000000")
	}

	@Test func debugDescriptionはdescriptionと同じ() {
		let value: BigInt = -123456789012345678901234567890

		#expect(value.debugDescription == value.description)
	}

	@Test func 基数と大文字小文字を指定して文字列にする() {
		let value: BigInt = -(BigInt(0xABCDEF) << 64)

		#expect(String(value, radix: 16) == "-abcdef0000000000000000")
		#expect(String(value, radix: 16, uppercase: true) == "-ABCDEF0000000000000000")
		#expect(String(BigInt(5), radix: 2) == "101")
		#expect(String(BigInt(1295), radix: 36) == "zz")
		#expect(String(BigInt(0), radix: 7) == "0")
	}

	@Test func すべての基数で往復できる() {
		let value: BigInt = -(BigInt(1) << 200) + 987654321

		for radix in 2 ... 36 {
			let text: String = String(value, radix: radix)

			#expect(BigInt(text, radix: radix) == value, "radix \(radix)")
		}
	}

	@Test func LosslessStringConvertibleとして使える() {
		func roundTrip<T: LosslessStringConvertible & Equatable>(_ value: T) -> Bool {
			T(value.description) == value
		}

		#expect(roundTrip(BigInt(-123456789012345678901234567890)))
	}

}
