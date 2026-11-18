@testable import BigInt
import UnitTesting


/// Java の `RoundingMode` のドキュメントの表（1 桁に丸める）。
/// 値は 10 倍した整数で表し、10 で割って丸める。
let roundingTable: [(tenfold: Int, expected: [RoundingRule: Int])] = [
	(55, [.awayFromZero: 6, .towardZero: 5, .up: 6, .down: 5, .toNearestOrAwayFromZero: 6, .toNearestOrTowardZero: 5, .toNearestOrEven: 6]),
	(25, [.awayFromZero: 3, .towardZero: 2, .up: 3, .down: 2, .toNearestOrAwayFromZero: 3, .toNearestOrTowardZero: 2, .toNearestOrEven: 2]),
	(16, [.awayFromZero: 2, .towardZero: 1, .up: 2, .down: 1, .toNearestOrAwayFromZero: 2, .toNearestOrTowardZero: 2, .toNearestOrEven: 2]),
	(11, [.awayFromZero: 2, .towardZero: 1, .up: 2, .down: 1, .toNearestOrAwayFromZero: 1, .toNearestOrTowardZero: 1, .toNearestOrEven: 1]),
	(10, [.awayFromZero: 1, .towardZero: 1, .up: 1, .down: 1, .toNearestOrAwayFromZero: 1, .toNearestOrTowardZero: 1, .toNearestOrEven: 1]),
	(-10, [.awayFromZero: -1, .towardZero: -1, .up: -1, .down: -1, .toNearestOrAwayFromZero: -1, .toNearestOrTowardZero: -1, .toNearestOrEven: -1]),
	(-11, [.awayFromZero: -2, .towardZero: -1, .up: -1, .down: -2, .toNearestOrAwayFromZero: -1, .toNearestOrTowardZero: -1, .toNearestOrEven: -1]),
	(-16, [.awayFromZero: -2, .towardZero: -1, .up: -1, .down: -2, .toNearestOrAwayFromZero: -2, .toNearestOrTowardZero: -2, .toNearestOrEven: -2]),
	(-25, [.awayFromZero: -3, .towardZero: -2, .up: -2, .down: -3, .toNearestOrAwayFromZero: -3, .toNearestOrTowardZero: -2, .toNearestOrEven: -2]),
	(-55, [.awayFromZero: -6, .towardZero: -5, .up: -5, .down: -6, .toNearestOrAwayFromZero: -6, .toNearestOrTowardZero: -5, .toNearestOrEven: -6]),
]


@Suite struct BigInt丸めテスト {

	// MARK: RoundingRule

	@Test func FloatingPointRoundingRuleから作れる() {
		#expect(RoundingRule(.towardZero) == .towardZero)
		#expect(RoundingRule(.awayFromZero) == .awayFromZero)
		#expect(RoundingRule(.up) == .up)
		#expect(RoundingRule(.down) == .down)
		#expect(RoundingRule(.toNearestOrEven) == .toNearestOrEven)
		#expect(RoundingRule(.toNearestOrAwayFromZero) == .toNearestOrAwayFromZero)
	}

	@Test func FloatingPointRoundingRuleへ変換できる() {
		for rule in RoundingRule.allCases {
			if rule == .toNearestOrTowardZero {
				#expect(rule.floatingPointRoundingRule == nil)
			}
			else {
				#expect(rule.floatingPointRoundingRule.map(RoundingRule.init) == rule)
			}
		}
	}

	// MARK: 丸め方付きの除算

	@Test func 丸め方がJavaのRoundingModeの表と一致する() {
		for row in roundingTable {
			for rule in RoundingRule.allCases {
				let (quotient, remainder) = BigInt(row.tenfold)
					.quotientAndRemainder(dividingBy: 10, rounding: rule)

				#expect(quotient == BigInt(row.expected[rule]!), "\(row.tenfold) \(rule)")
				#expect(quotient * 10 + remainder == BigInt(row.tenfold))
			}
		}
	}

	@Test func 除数が負でも真の商を丸める() {
		// 7 / -2 = -3.5
		let value: BigInt = 7

		#expect(value.quotientAndRemainder(dividingBy: -2, rounding: .towardZero).quotient == -3)
		#expect(value.quotientAndRemainder(dividingBy: -2, rounding: .down).quotient == -4)
		#expect(value.quotientAndRemainder(dividingBy: -2, rounding: .up).quotient == -3)
		#expect(value.quotientAndRemainder(dividingBy: -2, rounding: .toNearestOrEven).quotient == -4)
		#expect(value.quotientAndRemainder(dividingBy: -2, rounding: .toNearestOrTowardZero).quotient == -3)
	}

	@Test func 床への丸めはPythonの整数除算と同じ() {
		for (a, b, quotient, remainder) in [(7, 2, 3, 1), (-7, 2, -4, 1), (7, -2, -4, -1), (-7, -2, 3, -1)] {
			let result = BigInt(a).quotientAndRemainder(dividingBy: BigInt(b), rounding: .down)

			#expect(result.quotient == BigInt(quotient))
			#expect(result.remainder == BigInt(remainder))
		}
	}

	@Test func 割り切れるときは丸めない() {
		for rule in RoundingRule.allCases {
			let result = BigInt(-12).quotientAndRemainder(dividingBy: 4, rounding: rule)

			#expect(result.quotient == -3)
			#expect(result.remainder == 0)
		}
	}

	@Test func 商が0のときの丸め() {
		// 1 / 3 と -1 / 3
		#expect(BigInt(1).quotientAndRemainder(dividingBy: 3, rounding: .up).quotient == 1)
		#expect(BigInt(-1).quotientAndRemainder(dividingBy: 3, rounding: .up).quotient == 0)
		#expect(BigInt(-1).quotientAndRemainder(dividingBy: 3, rounding: .down).quotient == -1)
		#expect(BigInt(1).quotientAndRemainder(dividingBy: 2, rounding: .toNearestOrEven).quotient == 0)
		#expect(BigInt(-1).quotientAndRemainder(dividingBy: 2, rounding: .toNearestOrAwayFromZero).quotient == -1)
	}

	@Test func 多ワードの値の丸め() {
		let divisor: BigInt = BigInt(1) << 100
		let half: BigInt = BigInt(1) << 99

		// (3 * 2^100 + 2^99) / 2^100 = 3.5
		let tie: BigInt = 3 * divisor + half

		#expect(tie.quotientAndRemainder(dividingBy: divisor, rounding: .toNearestOrEven).quotient == 4)
		#expect(tie.quotientAndRemainder(dividingBy: divisor, rounding: .toNearestOrTowardZero).quotient == 3)
		#expect((tie + 1).quotientAndRemainder(dividingBy: divisor, rounding: .toNearestOrTowardZero).quotient == 4)
		#expect((tie - 1).quotientAndRemainder(dividingBy: divisor, rounding: .toNearestOrAwayFromZero).quotient == 3)
	}

	// MARK: 冪

	@Test func power() {
		#expect(BigInt(0).power(0) == 1)
		#expect(BigInt(0).power(5) == 0)
		#expect(BigInt(2).power(100) == BigInt(1) << 100)
		#expect(BigInt(-3).power(3) == -27)
		#expect(BigInt(-3).power(4) == 81)
		#expect(BigInt(10).power(30) == 1000000000000000000000000000000)
		#expect(BigInt(7).power(1) == 7)
	}

	// MARK: 10進の桁数

	@Test func decimalDigitCount() {
		#expect(BigInt(0).decimalDigitCount == 1)
		#expect(BigInt(1).decimalDigitCount == 1)
		#expect(BigInt(-1).decimalDigitCount == 1)
		#expect(BigInt(9).decimalDigitCount == 1)
		#expect(BigInt(10).decimalDigitCount == 2)
		#expect(BigInt(-99).decimalDigitCount == 2)
		#expect(BigInt(UInt.max).decimalDigitCount == 20)
	}

	@Test func 十の冪の境界の桁数() {
		let ten: BigInt = 10

		for digits in 1 ... 120 {
			let power: BigInt = ten.power(digits)

			#expect((power - 1).decimalDigitCount == digits)
			#expect(power.decimalDigitCount == digits + 1)
			#expect((-power).decimalDigitCount == digits + 1)
		}
	}

	@Test func 桁数は文字列の長さと一致する() {
		for vector in representationVectors {
			let value: BigInt = BigInt(vector.decimal)!

			#expect(value.decimalDigitCount == value.magnitude.description.count)
		}
	}

}
