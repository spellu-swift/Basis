@testable import BigInt
import UnitTesting


@Suite struct BigInt生成テスト {

	// MARK: 整数リテラル

	@Test func 整数リテラルから作れる() {
		let zero: BigInt = 0
		let one: BigInt = 1
		let minusOne: BigInt = -1

		#expect(zero.isZero)
		#expect(one.description == "1")
		#expect(minusOne.description == "-1")
	}

	@Test func 六十四ビットを超える整数リテラルから作れる() {
		let positive: BigInt = 123456789012345678901234567890
		let negative: BigInt = -340282366920938463463374607431768211456

		#expect(positive.description == "123456789012345678901234567890")
		#expect(negative.description == "-340282366920938463463374607431768211456")
	}

	@Test func ワードの境界の整数リテラル() {
		let max: BigInt = 18446744073709551615
		let maxPlusOne: BigInt = 18446744073709551616
		let minusTwoTo63: BigInt = -9223372036854775808

		#expect(max == BigInt(UInt.max))
		#expect(maxPlusOne == BigInt(UInt.max) + 1)
		#expect(minusTwoTo63 == BigInt(Int.min))
	}

	// MARK: 整数型から

	@Test func 符号付き整数型から作れる() {
		#expect(BigInt(Int8.min).description == "-128")
		#expect(BigInt(Int8.max).description == "127")
		#expect(BigInt(Int.min).description == "-9223372036854775808")
		#expect(BigInt(Int.max).description == "9223372036854775807")
		#expect(BigInt(0 as Int).isZero)
		#expect(BigInt(-1 as Int).description == "-1")
	}

	@Test func 符号なし整数型から作れる() {
		#expect(BigInt(UInt8.max).description == "255")
		#expect(BigInt(UInt.max).description == "18446744073709551615")
		#expect(BigInt(0 as UInt).isZero)
	}

	@Test func BigIntから作ると同じ値になる() {
		let value: BigInt = -123456789012345678901234567890

		#expect(BigInt(value) == value)
	}

	@Test func exactlyは常に成功する() {
		#expect(BigInt(exactly: Int.min) == BigInt(Int.min))
		#expect(BigInt(exactly: UInt.max) == BigInt(UInt.max))
	}

	@Test func truncatingIfNeededとclampingは元の値と等しい() {
		#expect(BigInt(truncatingIfNeeded: UInt.max) == BigInt(UInt.max))
		#expect(BigInt(truncatingIfNeeded: Int8(-1)) == -1)
		#expect(BigInt(clamping: Int.min) == BigInt(Int.min))
		#expect(BigInt(clamping: UInt64.max) == BigInt(UInt64.max))
	}

	// MARK: 浮動小数点数から

	@Test func 浮動小数点数の小数部は0方向に切り捨てる() {
		#expect(BigInt(3.7) == 3)
		#expect(BigInt(-3.7) == -3)
		#expect(BigInt(0.9) == 0)
		#expect(BigInt(-0.9) == 0)
		#expect(BigInt(-0.0) == 0)
		#expect(BigInt(Float(16777216)) == 16777216)
	}

	@Test func 大きな浮動小数点数から作れる() {
		#expect(BigInt(1e30) == 1000000000000000019884624838656)
		#expect(BigInt(-0x1p100) == -(BigInt(1) << 100))
		#expect(BigInt(Double.greatestFiniteMagnitude) == (BigInt(1) << 1024) - (BigInt(1) << 971))
	}

	@Test func 浮動小数点数からexactlyで作れるのは整数のときだけ() {
		#expect(BigInt(exactly: 2.0) == 2)
		#expect(BigInt(exactly: -0x1p80) == -(BigInt(1) << 80))
		#expect(BigInt(exactly: 2.5) == nil)
		#expect(BigInt(exactly: Double.nan) == nil)
		#expect(BigInt(exactly: Double.infinity) == nil)
		#expect(BigInt(exactly: -Double.infinity) == nil)
	}

}
