@testable import BigDecimal
import UnitTesting


@Suite struct BigDecimal変換テスト {

	private func parse(_ text: String) -> BigDecimal {
		BigDecimal(text)!
	}

	// MARK: 文字列

	@Test func descriptionはJavaのドキュメントの例と一致する() {
		let cases: [(unscaled: BigInt, scale: Int, text: String)] = [
			(123, 0, "123"),
			(123, -1, "1.23E+3"),
			(123, 5, "0.00123"),
			(123, 10, "1.23E-8"),
			(-123, 12, "-1.23E-10"),
		]

		for item in cases {
			let value: BigDecimal = .init(unscaledValue: item.unscaled, scale: item.scale)

			#expect(value.description == item.text)
			#expect(value.debugDescription == item.text)
		}
	}

	@Test func 調整済み指数がマイナス6の境界() {
		#expect(parse("0.000001").description == "0.000001")
		#expect(parse("0.0000001").description == "1E-7")
		#expect(parse("0.00000123").description == "0.00000123")
		#expect(parse("0.000000123").description == "1.23E-7")
	}

	@Test func descriptionから値とスケールが元に戻る() {
		let values: [BigDecimal] = [
			.init(unscaledValue: 0, scale: -3),
			.init(unscaledValue: 0, scale: 12),
			.init(unscaledValue: -1, scale: Int.max),
			.init(unscaledValue: 1, scale: Int.min),
			.init(unscaledValue: 123456789, scale: -7),
			parse("-12.3400"),
		]

		for value in values {
			#expect(BigDecimal(value.description)?.isIdentical(to: value) == true, "\(value)")
		}
	}

	@Test func plainStringは指数を使わない() {
		#expect(parse("1.23E+3").plainString == "1230")
		#expect(parse("1.23E-8").plainString == "0.0000000123")
		#expect(parse("-0.00").plainString == "0.00")
		#expect(parse("0E+3").plainString == "0")
	}

	@Test func LosslessStringConvertibleとして使える() {
		func roundTrip<T: LosslessStringConvertible & Equatable>(_ value: T) -> Bool {
			T(value.description) == value
		}

		#expect(roundTrip(parse("-12.3400")))
	}

	// MARK: 整数

	@Test func 小数部が0なら整数型にできる() {
		#expect(Int(exactly: parse("42.000")) == 42)
		#expect(Int(exactly: parse("-1E+3")) == -1000)
		#expect(BigInt(exactly: parse("1E+30")) == BigInt(10).power(30))
		#expect(Int8(exactly: parse("127.0")) == 127)
	}

	@Test func 小数部があるか範囲外ならnil() {
		#expect(Int(exactly: parse("42.5")) == nil)
		#expect(Int8(exactly: parse("128")) == nil)
		#expect(UInt(exactly: parse("-1")) == nil)
		#expect(BigInt(exactly: parse("0.001")) == nil)
	}

	@Test func 丸めて整数にする() {
		#expect(parse("2.5").bigInt(rounding: .toNearestOrEven) == 2)
		#expect(parse("-2.5").bigInt(rounding: .towardZero) == -2)
		#expect(parse("1E+3").bigInt(rounding: .towardZero) == 1000)
	}

	// MARK: Double

	@Test func Doubleへの変換は最近接の偶数() {
		#expect(Double(parse("0.1")) == 0.1)
		#expect(Double(parse("-123.456")) == -123.456)
		#expect(Double(parse("1E+3")) == 1000)
		// 2^53 + 1 は 2^53 と 2^53 + 2 の中間
		#expect(Double(parse("9007199254740993")) == 9007199254740992)
		#expect(Double(parse("9007199254740993.0000000000000001")) == 9007199254740994)
	}

	@Test func 極端な値のDoubleへの変換() {
		#expect(Double(parse("1E+400")) == .infinity)
		#expect(Double(parse("-1E+400")) == -.infinity)
		#expect(Double(parse("1E-400")) == 0)
		#expect(Double(parse("1.7976931348623157E+308")) == .greatestFiniteMagnitude)
		#expect(Double(parse("4.9E-324")) == .leastNonzeroMagnitude)
		#expect(Double(parse("2.2250738585072014E-308")) == .leastNormalMagnitude)
		#expect(Double(parse("1E-320")) == 1e-320)
		#expect(Double(BigDecimal(unscaledValue: 1, scale: 1_000_000_000)) == 0)
		#expect(Double(BigDecimal(unscaledValue: 1, scale: -1_000_000_000)) == .infinity)
	}

	@Test func 浮動小数点数との往復() {
		for double in [0.1, -2.5, 1e-300, 123456.789, Double.leastNonzeroMagnitude, Double.greatestFiniteMagnitude] {
			#expect(Double(BigDecimal(exactly: double)!) == double, "\(double)")
			#expect(Double(BigDecimal(roundTripping: double)!) == double, "\(double)")
		}
	}

	@Test func Doubleのexactlyはちょうど表せるときだけ() {
		#expect(Double(exactly: parse("0.5")) == 0.5)
		#expect(Double(exactly: parse("1E+3")) == 1000)
		#expect(Double(exactly: parse("0.1")) == nil)
		#expect(Double(exactly: parse("1E+400")) == nil)
	}

}
