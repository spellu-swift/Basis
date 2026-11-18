@testable import BigDecimal
import UnitTesting


/// Python の decimal で作った期待値と照合する。
@Suite struct BigDecimal期待値テスト {

	private func parse(_ text: String) -> BigDecimal {
		BigDecimal(text)!
	}

	private func rule(_ name: String) -> RoundingRule {
		RoundingRule.allCases.first { "\($0)" == name }!
	}

	@Test func 加減乗算と比較() {
		for vector in arithmeticVectors {
			let a: BigDecimal = parse(vector.a)
			let b: BigDecimal = parse(vector.b)
			let context: Comment = "\(vector.a), \(vector.b)"

			#expect((a + b).description == vector.sum, context)
			#expect((a - b).description == vector.difference, context)
			#expect((a * b).description == vector.product, context)
			#expect((a < b) == (vector.order < 0), context)
			#expect((a == b) == (vector.order == 0), context)
		}
	}

	@Test func 整数部の商と剰余と厳密な商() {
		for vector in divisionVectors {
			let a: BigDecimal = parse(vector.a)
			let b: BigDecimal = parse(vector.b)
			let (quotient, remainder) = a.quotientAndRemainder(dividingBy: b)
			let context: Comment = "\(vector.a), \(vector.b)"

			#expect(quotient.description == vector.quotient, context)
			#expect(remainder.description == vector.remainder, context)
			#expect(a.truncatingRemainder(dividingBy: b).description == vector.remainder, context)
			#expect(a.dividedExactly(by: b)?.description == vector.exactly, context)
		}
	}

	@Test func 丸め方を指定した除算() {
		for vector in divisionRoundingVectors {
			let a: BigDecimal = parse(vector.a)
			let b: BigDecimal = parse(vector.b)
			let rule: RoundingRule = rule(vector.rule)
			let context: Comment = "\(vector.a), \(vector.b), \(vector.rule)"

			#expect(a.divided(by: b, scale: 2, rounding: rule).description == vector.scale2, context)
			#expect(a.divided(by: b, precision: 5, rounding: rule).description == vector.precision5, context)
		}
	}

	@Test func 表現() {
		for vector in representationVectors {
			let value: BigDecimal = parse(vector.value)
			let context: Comment = "\(vector.value)"

			#expect(value.description == vector.description, context)
			#expect(value.plainString == vector.plainString, context)
			#expect(value.normalized().description == vector.normalized, context)
			#expect(value.precision == vector.precision, context)
			#expect(value.isInteger == vector.isInteger, context)
			#expect(Double(value) == Double(vector.nearestDouble)!, context)
		}
	}

	@Test func 丸め() {
		for vector in roundingVectors {
			let value: BigDecimal = parse(vector.value)
			let rule: RoundingRule = rule(vector.rule)
			let context: Comment = "\(vector.value), \(vector.rule)"

			#expect(value.rounded(scale: -1, rule).description == vector.scaleMinus1, context)
			#expect(value.rounded(scale: 0, rule).description == vector.scale0, context)
			#expect(value.rounded(scale: 1, rule).description == vector.scale1, context)
			#expect(value.rounded(scale: 2, rule).description == vector.scale2, context)
			#expect(value.rounded(precision: 1, rule).description == vector.precision1, context)
			#expect(value.rounded(precision: 2, rule).description == vector.precision2, context)
			#expect(value.rounded(precision: 3, rule).description == vector.precision3, context)
			#expect(value.bigInt(rounding: rule).description == vector.integer, context)
		}
	}

}
