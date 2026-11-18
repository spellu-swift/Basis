@testable import BigDecimal
import UnitTesting


@Suite struct BigDecimal丸めテスト {

	private func parse(_ text: String) -> BigDecimal {
		BigDecimal(text)!
	}

	// MARK: スケールを指定した丸め

	@Test func 丸め方がJavaのRoundingModeの表と一致する() {
		// Java の RoundingMode のドキュメントの表（1 桁に丸める）
		let table: [(value: String, expected: [RoundingRule: String])] = [
			("5.5", [.awayFromZero: "6", .towardZero: "5", .up: "6", .down: "5", .toNearestOrAwayFromZero: "6", .toNearestOrTowardZero: "5", .toNearestOrEven: "6"]),
			("2.5", [.awayFromZero: "3", .towardZero: "2", .up: "3", .down: "2", .toNearestOrAwayFromZero: "3", .toNearestOrTowardZero: "2", .toNearestOrEven: "2"]),
			("1.6", [.awayFromZero: "2", .towardZero: "1", .up: "2", .down: "1", .toNearestOrAwayFromZero: "2", .toNearestOrTowardZero: "2", .toNearestOrEven: "2"]),
			("1.1", [.awayFromZero: "2", .towardZero: "1", .up: "2", .down: "1", .toNearestOrAwayFromZero: "1", .toNearestOrTowardZero: "1", .toNearestOrEven: "1"]),
			("-1.1", [.awayFromZero: "-2", .towardZero: "-1", .up: "-1", .down: "-2", .toNearestOrAwayFromZero: "-1", .toNearestOrTowardZero: "-1", .toNearestOrEven: "-1"]),
			("-2.5", [.awayFromZero: "-3", .towardZero: "-2", .up: "-2", .down: "-3", .toNearestOrAwayFromZero: "-3", .toNearestOrTowardZero: "-2", .toNearestOrEven: "-2"]),
			("-5.5", [.awayFromZero: "-6", .towardZero: "-5", .up: "-5", .down: "-6", .toNearestOrAwayFromZero: "-6", .toNearestOrTowardZero: "-5", .toNearestOrEven: "-6"]),
		]

		for row in table {
			for rule in RoundingRule.allCases {
				#expect(parse(row.value).rounded(scale: 0, rule).description == row.expected[rule], "\(row.value) \(rule)")
			}
		}
	}

	@Test func スケールを増やすと末尾に0を足す() {
		#expect(parse("1.5").rounded(scale: 3, .towardZero).description == "1.500")
		#expect(parse("1E+2").rounded(scale: 0, .towardZero).description == "100")
	}

	// MARK: 桁数を指定した丸め

	@Test func 繰り上がりで桁が増えたら末尾の0を落とす() {
		let value: BigDecimal = parse("9.995")

		#expect(value.rounded(precision: 3, .toNearestOrEven).description == "10.0")
		#expect(value.rounded(precision: 1, .up).description == "1E+1")
	}

	@Test func 桁数が収まっていれば変えない() {
		let value: BigDecimal = parse("1.20")

		#expect(value.rounded(precision: 3, .awayFromZero).isIdentical(to: value))
		#expect(value.rounded(precision: 10, .awayFromZero).isIdentical(to: value))
	}

	// MARK: 丸めずにスケールを変える

	@Test func settingScaleは値が変わるならnil() {
		#expect(parse("1.500").settingScale(1)?.description == "1.5")
		#expect(parse("1.5").settingScale(3)?.description == "1.500")
		#expect(parse("1E+3").settingScale(-2)?.description == "1.0E+3")
		#expect(parse("1.55").settingScale(1) == nil)
		#expect(parse("1E+3").settingScale(-4) == nil)
	}

	// MARK: 正規化

	@Test func normalizedは末尾の0を取り除く() {
		#expect(parse("600.0").normalized().isIdentical(to: .init(unscaledValue: 6, scale: -2)))
		#expect(parse("1.2300").normalized().description == "1.23")
		#expect(parse("0.000").normalized().isIdentical(to: .init(unscaledValue: 0, scale: 0)))
		#expect(parse("-5").normalized().description == "-5")
	}

	// MARK: 整数部と小数部

	@Test func 整数部と小数部() {
		#expect(parse("12.345").integerPart.description == "12")
		#expect(parse("12.345").fractionalPart.description == "0.345")
		#expect(parse("-12.345").integerPart.description == "-12")
		#expect(parse("-12.345").fractionalPart.description == "-0.345")
		#expect(parse("0.5").integerPart.description == "0")
		#expect(parse("1E+3").integerPart.description == "1E+3")
		#expect(parse("1E+3").fractionalPart.description == "0")
		#expect(parse("7").fractionalPart.description == "0")
	}

	@Test func 整数部と小数部の和は元の値() {
		for text in ["12.345", "-12.345", "0.001", "-7.0", "1E+3"] {
			let value: BigDecimal = parse(text)

			#expect(value.integerPart + value.fractionalPart == value, "\(text)")
		}
	}

	// MARK: 除算

	@Test func 桁数を指定した除算はJavaのドキュメントの例と一致する() {
		// Java の BigDecimal のドキュメント：精度 3・FLOOR で 19/100 = 0.19、21/110 = 0.190
		#expect(parse("19").divided(by: parse("100"), precision: 3, rounding: .down).description == "0.19")
		#expect(parse("21").divided(by: parse("110"), precision: 3, rounding: .down).description == "0.190")
	}

	@Test func スケールを指定した除算() {
		#expect(parse("1").divided(by: parse("3"), scale: 4, rounding: .toNearestOrAwayFromZero).description == "0.3333")
		#expect(parse("2").divided(by: parse("3"), scale: 2, rounding: .toNearestOrAwayFromZero).description == "0.67")
		#expect(parse("-2").divided(by: parse("3"), scale: 0, rounding: .down).description == "-1")
		#expect(parse("10").divided(by: parse("4"), scale: -1, rounding: .toNearestOrEven).description == "0E+1")
	}

	@Test func 厳密な除算は割り切れなければnil() {
		#expect(parse("1").dividedExactly(by: parse("3")) == nil)
		#expect(parse("1").dividedExactly(by: parse("4"))?.description == "0.25")
		#expect(parse("1.00").dividedExactly(by: parse("4"))?.description == "0.25")
		#expect(parse("100").dividedExactly(by: parse("4"))?.description == "25")
		#expect(parse("6.0").dividedExactly(by: parse("2"))?.description == "3.0")
		#expect(parse("1.000").dividedExactly(by: parse("1"))?.description == "1.000")
		#expect(parse("0.00").dividedExactly(by: parse("7"))?.description == "0.00")
	}

	@Test func 除数の桁が多い厳密な除算() {
		let divisor: BigDecimal = .init(unscaledValue: BigInt(2).power(200), scale: 0)
		let quotient: BigDecimal? = BigDecimal(1).dividedExactly(by: divisor)

		#expect(quotient != nil)
		#expect(quotient.map { $0 * divisor } == 1)
	}

}
