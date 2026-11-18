@testable import BigInt
import UnitTesting


@Suite struct BigInt算術テスト {

	private func parse(_ text: String) -> BigInt {
		BigInt(text)!
	}

	// MARK: 期待値との照合

	@Test func 加減乗除がPythonの結果と一致する() {
		for vector in arithmeticVectors {
			let a: BigInt = parse(vector.a)
			let b: BigInt = parse(vector.b)

			#expect((a + b).description == vector.sum)
			#expect((a - b).description == vector.difference)
			#expect((a * b).description == vector.product)
			#expect((a / b).description == vector.quotient)
			#expect((a % b).description == vector.remainder)
		}
	}

	@Test func 商と剰余は除算の恒等式を満たす() {
		for vector in arithmeticVectors {
			let a: BigInt = parse(vector.a)
			let b: BigInt = parse(vector.b)
			let (quotient, remainder) = a.quotientAndRemainder(dividingBy: b)

			#expect(quotient * b + remainder == a)
			#expect(remainder.magnitude < b.magnitude)
			#expect(remainder.isZero || (remainder < 0) == (a < 0))
		}
	}

	// MARK: 符号

	@Test func 除算は0方向に切り捨て剰余は被除数の符号() {
		#expect(BigInt(7) / 2 == 3)
		#expect(BigInt(-7) / 2 == -3)
		#expect(BigInt(7) / -2 == -3)
		#expect(BigInt(-7) / -2 == 3)
		#expect(BigInt(7) % 2 == 1)
		#expect(BigInt(-7) % 2 == -1)
		#expect(BigInt(7) % -2 == 1)
		#expect(BigInt(-7) % -2 == -1)
	}

	@Test func 絶対値の小さい数を大きい数で割ると商は0() {
		let small: BigInt = 5
		let large: BigInt = 123456789012345678901234567890

		#expect(small / large == 0)
		#expect(small % large == small)
		#expect(-small % large == -small)
	}

	@Test func 結果が0になる演算の符号は正() {
		let value: BigInt = 123456789012345678901234567890

		#expect((value - value).isZero)
		#expect((-value + value).signum() == 0)
		#expect((value * 0).signum() == 0)
		#expect((-value * 0).description == "0")
		#expect((-value % value).description == "0")
	}

	// MARK: 複合代入

	@Test func 複合代入演算子() {
		var value: BigInt = 10

		value += 5
		#expect(value == 15)
		value -= 20
		#expect(value == -5)
		value *= -4
		#expect(value == 20)
		value /= 3
		#expect(value == 6)
		value %= 4
		#expect(value == 2)
	}

	@Test func 単項マイナスとnegate() {
		var value: BigInt = 123456789012345678901234567890

		#expect((-value).description == "-123456789012345678901234567890")
		value.negate()
		#expect(value.description == "-123456789012345678901234567890")
		#expect((-BigInt(0)).isZero)
	}

	// MARK: 符号と絶対値

	@Test func magnitudeは絶対値() {
		let negative: BigInt = -123456789012345678901234567890

		#expect(negative.magnitude.description == "123456789012345678901234567890")
		#expect(BigInt(0).magnitude == 0)
		#expect(BigInt(5).magnitude == 5)
	}

	@Test func signumは符号() {
		#expect(BigInt(-123456789012345678901234567890).signum() == -1)
		#expect(BigInt(0).signum() == 0)
		#expect(BigInt(123456789012345678901234567890).signum() == 1)
	}

	@Test func isZero() {
		#expect(BigInt(0).isZero)
		#expect(!BigInt(1).isZero)
		#expect(!BigInt(-1).isZero)
	}

	// MARK: 比較とハッシュ

	@Test func 大小比較() {
		let values: [BigInt] = [
			-(BigInt(1) << 128),
			BigInt(Int.min),
			-1,
			0,
			1,
			BigInt(UInt.max),
			BigInt(1) << 128,
		]

		for (i, lhs) in values.enumerated() {
			for (j, rhs) in values.enumerated() {
				#expect((lhs < rhs) == (i < j))
				#expect((lhs == rhs) == (i == j))
			}
		}
	}

	@Test func 等しい値はハッシュも等しい() {
		let a: BigInt = parse("123456789012345678901234567890")
		let b: BigInt = parse("123456789012345") * 1_000_000_000_000_000
			+ parse("678901234567890")

		#expect(a == b)
		#expect(a.hashValue == b.hashValue)
		#expect(Set([a, b]).count == 1)
	}

	@Test func 整数型との比較() {
		let value: BigInt = 5

		#expect(value == 5 as Int)
		#expect(value < 6 as UInt8)
		#expect(BigInt(-1) < 0 as UInt)
		#expect(BigInt(UInt.max) > Int.max)
	}

	// MARK: Strideable

	@Test func distanceとadvanced() {
		let a: BigInt = 10
		let b: BigInt = BigInt(1) << 100

		#expect(a.distance(to: b) == b - a)
		#expect(a.advanced(by: b - a) == b)
	}

	@Test func 範囲を繰り返せる() {
		let values: [BigInt] = Array((BigInt(-2) ..< 3))

		#expect(values == [-2, -1, 0, 1, 2])
		#expect(Array(stride(from: BigInt(0), to: 10, by: 4)) == [0, 4, 8])
	}

}
