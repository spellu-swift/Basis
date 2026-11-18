@testable import BigInt
import UnitTesting


@Suite struct BigIntビットテスト {

	private func parse(_ text: String) -> BigInt {
		BigInt(text)!
	}

	// MARK: 期待値との照合

	@Test func ビット演算がPythonの結果と一致する() {
		for vector in arithmeticVectors {
			let a: BigInt = parse(vector.a)
			let b: BigInt = parse(vector.b)

			#expect((a & b).description == vector.and)
			#expect((a | b).description == vector.or)
			#expect((a ^ b).description == vector.xor)
		}
	}

	@Test func ビットの情報とシフトがPythonの結果と一致する() {
		for vector in representationVectors {
			let value: BigInt = parse(vector.decimal)

			#expect(value.bitWidth == vector.bitWidth)
			#expect(value.trailingZeroBitCount == vector.trailingZeroBitCount)
			#expect((value << 70).description == vector.shiftedLeft70)
			#expect((value >> 70).description == vector.shiftedRight70)
			#expect((value >> 3).description == vector.shiftedRight3)
			#expect((~value).description == vector.inverted)
		}
	}

	// MARK: bitWidth

	@Test func bitWidthは符号ビットを含む最小のビット数() {
		#expect(BigInt(0).bitWidth == 1)
		#expect(BigInt(1).bitWidth == 2)
		#expect(BigInt(255).bitWidth == 9)
		#expect(BigInt(-1).bitWidth == 1)
		#expect(BigInt(-8).bitWidth == 4)
		#expect(BigInt(-5).bitWidth == 4)
		#expect(BigInt(UInt.max).bitWidth == 65)
		#expect(BigInt(Int.min).bitWidth == 64)
	}

	@Test func trailingZeroBitCount() {
		#expect(BigInt(0).trailingZeroBitCount == 1)
		#expect(BigInt(1).trailingZeroBitCount == 0)
		#expect(BigInt(-8).trailingZeroBitCount == 3)
		#expect((BigInt(1) << 130).trailingZeroBitCount == 130)
	}

	// MARK: words

	@Test func wordsは符号拡張した2の補数() {
		#expect(BigInt(0).words == [0])
		#expect(BigInt(1).words == [1])
		#expect(BigInt(-1).words == [UInt.max])
		#expect(BigInt(UInt.max).words == [UInt.max, 0])
		#expect(BigInt(Int.min).words == [UInt(1) << 63])
		#expect((-(BigInt(1) << 64)).words == [0, UInt.max])
	}

	@Test func wordsから作る() {
		#expect(BigInt(words: []) == 0)
		#expect(BigInt(words: [1]) == 1)
		#expect(BigInt(words: [UInt.max]) == -1)
		#expect(BigInt(words: [UInt.max, 0]) == BigInt(UInt.max))
		#expect(BigInt(words: [UInt(1) << 63]) == BigInt(Int.min))
		#expect(BigInt(words: [0, UInt.max]) == -(BigInt(1) << 64))

		// 余分な符号拡張のワードは無視する
		#expect(BigInt(words: [5, 0, 0]) == 5)
		#expect(BigInt(words: [UInt.max, UInt.max]) == -1)
	}

	@Test(arguments: ["0", "1", "-1", "18446744073709551616", "-18446744073709551616", "-170141183460469231731687303715884105728"])
	func wordsと往復できる(
		string: String,
	) throws {
		let value: BigInt = try #require(BigInt(string))

		#expect(BigInt(words: value.words) == value)
	}

	@Test func 符号と絶対値のワード列から作る() {
		#expect(BigInt(_isNegative: false, limbs: []) == 0)
		#expect(BigInt(_isNegative: true, limbs: []) == 0)
		#expect(BigInt(_isNegative: true, limbs: [0]) == 0)
		#expect(BigInt(_isNegative: false, limbs: [UInt.max]) == BigInt(UInt.max))
		#expect(BigInt(_isNegative: true, limbs: [0, 1, 0]) == -(BigInt(1) << 64))
	}

	// MARK: ビット演算

	@Test func 負の数は無限長の2の補数として扱う() {
		#expect(BigInt(-1) & 0xFF == 0xFF)
		#expect(BigInt(-256) | 0xFF == -1)
		#expect(BigInt(-1) ^ 0xFF == -256)
		#expect(~BigInt(0) == -1)
		#expect(~BigInt(-1) == 0)
	}

	@Test func ビット演算の複合代入() {
		var value: BigInt = 0b1100

		value &= 0b1010
		#expect(value == 0b1000)
		value |= 0b0011
		#expect(value == 0b1011)
		value ^= 0b1111
		#expect(value == 0b0100)
	}

	// MARK: シフト

	@Test func 右シフトは負の無限大方向に丸める() {
		#expect(BigInt(-1) >> 1 == -1)
		#expect(BigInt(-5) >> 1 == -3)
		#expect(BigInt(5) >> 1 == 2)
		#expect(BigInt(-(BigInt(1) << 64)) >> 64 == -1)
		#expect(BigInt(-(BigInt(1) << 64) - 1) >> 64 == -2)
	}

	@Test func 負のシフト量は逆向きになる() {
		#expect(BigInt(1) << -1 == 0)
		#expect(BigInt(4) << -1 == 2)
		#expect(BigInt(1) >> -3 == 8)
	}

	@Test func 大きすぎる右シフトは0か負の1になる() {
		let huge: BigInt = BigInt(1) << 100

		#expect(BigInt(123) >> huge == 0)
		#expect(BigInt(-123) >> huge == -1)
		#expect(BigInt(123) << -huge == 0)
		#expect(BigInt(0) << huge == 0)
		#expect(BigInt(5) >> Int.max == 0)
		#expect(BigInt(-5) >> Int.max == -1)
		#expect(BigInt(-5) << Int.min == -1)
	}

	@Test func シフト量は異なる整数型で指定できる() {
		#expect(BigInt(1) << UInt8(65) == BigInt(1) << 65)
		#expect(BigInt(1) << BigInt(65) == BigInt(1) << 65)
	}

	@Test func シフトの複合代入() {
		var value: BigInt = 1

		value <<= 100
		#expect(value == BigInt(1) << 100)
		value >>= 99
		#expect(value == 2)
	}

}
