@testable import BigDecimal
import UnitTesting


@Suite struct BigDecimal算術テスト {

	private func parse(_ text: String) -> BigDecimal {
		BigDecimal(text)!
	}

	// MARK: 結果のスケール

	@Test func 加減算のスケールは大きいほう() {
		#expect((parse("1.10") + parse("2.5")).description == "3.60")
		#expect((parse("1.10") - parse("2.5")).description == "-1.40")
		#expect((parse("1E+3") + parse("1")).description == "1001")
	}

	@Test func 乗算のスケールは和() {
		#expect((parse("1.5") * parse("2.25")).description == "3.375")
		#expect((parse("1.30") * parse("1.20")).description == "1.5600")
		#expect((parse("1E+3") * parse("0.01")).description == "1E+1")
	}

	@Test func 十進の小数は誤差なく足せる() {
		#expect(parse("0.1") + parse("0.2") == parse("0.3"))
	}

	// MARK: 複合代入と符号

	@Test func 複合代入演算子() {
		var value: BigDecimal = parse("10.00")

		value += parse("0.5")
		#expect(value.description == "10.50")
		value -= 20
		#expect(value.description == "-9.50")
		value *= parse("0.1")
		#expect(value.description == "-0.950")
	}

	@Test func 単項マイナスとnegateはスケールを保つ() {
		var value: BigDecimal = parse("1.50")

		#expect((-value).description == "-1.50")
		value.negate()
		#expect(value.description == "-1.50")
		#expect((-parse("0.00")).description == "0.00")
	}

	@Test func magnitudeはスケールを保つ() {
		#expect(parse("-1.50").magnitude.description == "1.50")
		#expect(parse("2E+3").magnitude.description == "2E+3")
	}

	@Test func signumとisZero() {
		#expect(parse("-0.001").signum() == -1)
		#expect(parse("0.000").signum() == 0)
		#expect(parse("1E+10").signum() == 1)
		#expect(parse("0.00").isZero)
		#expect(parse("0E+5").isZero)
		#expect(!parse("0.01").isZero)
	}

	// MARK: 桁

	@Test func isIntegerは小数部が0か() {
		#expect(parse("2.00").isInteger)
		#expect(parse("2E+3").isInteger)
		#expect(parse("-7").isInteger)
		#expect(!parse("2.01").isInteger)
		#expect(!parse("-0.5").isInteger)
	}

	@Test func precisionは非スケール値の桁数() {
		#expect(parse("0").precision == 1)
		#expect(parse("0.00").precision == 1)
		#expect(parse("123.45").precision == 5)
		#expect(parse("-1E+5").precision == 1)
	}

	@Test func multipliedByPowerOfTenはスケールだけ変える() {
		let value: BigDecimal = parse("1.23")

		#expect(value.multipliedByPowerOfTen(2).isIdentical(to: .init(unscaledValue: 123, scale: 0)))
		#expect(value.multipliedByPowerOfTen(-2).description == "0.0123")
		#expect(value.multipliedByPowerOfTen(5).description == "1.23E+5")
	}

	// MARK: 等価性と順序

	@Test func 等価性は値で判定する() {
		#expect(parse("1.0") == parse("1.00"))
		#expect(parse("1") == parse("1E+0"))
		#expect(parse("100") == parse("1E+2"))
		#expect(parse("0") == parse("0.000"))
		#expect(parse("0") == parse("0E+5"))
		#expect(parse("1.0") != parse("1.01"))
		#expect(parse("-1") != parse("1"))
	}

	@Test func 等しい値はハッシュも等しい() {
		let values: [BigDecimal] = [parse("1"), parse("1.0"), parse("1.00"), parse("1E+0"), parse("0.1E+1")]

		for value in values {
			#expect(value.hashValue == values[0].hashValue)
		}

		#expect(Set(values).count == 1)
		#expect(Set([parse("0"), parse("0.00"), parse("0E+3")]).count == 1)
		#expect([parse("2.50"): "found"][parse("2.5")] == "found")
	}

	@Test func isIdenticalはスケールまで比べる() {
		#expect(parse("1.0").isIdentical(to: parse("1.0")))
		#expect(!parse("1.0").isIdentical(to: parse("1.00")))
		#expect(!parse("0").isIdentical(to: parse("0.0")))
	}

	@Test func 大小比較() {
		let values: [BigDecimal] = [
			parse("-1E+100"),
			parse("-123.45"),
			parse("-0.001"),
			parse("0"),
			parse("1E-100"),
			parse("0.9999"),
			parse("1.00"),
			parse("1.001"),
			parse("1E+100"),
		]

		for (i, lhs) in values.enumerated() {
			for (j, rhs) in values.enumerated() {
				#expect((lhs < rhs) == (i < j), "\(lhs) \(rhs)")
				#expect((lhs == rhs) == (i == j), "\(lhs) \(rhs)")
			}
		}
	}

	@Test func スケールが大きく違う値も比較できる() {
		let huge: BigDecimal = .init(unscaledValue: 1, scale: -1_000_000_000)
		let tiny: BigDecimal = .init(unscaledValue: 1, scale: 1_000_000_000)

		#expect(tiny < huge)
		#expect(huge != tiny)
		#expect(-huge < tiny)
	}

}
