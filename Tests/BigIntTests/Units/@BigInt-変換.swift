@testable import BigInt
import UnitTesting


@Suite struct BigInt変換テスト {

	// MARK: 整数型へ

	@Test func 範囲内ならexactlyで整数型にできる() {
		#expect(Int(exactly: BigInt(Int.min)) == Int.min)
		#expect(Int(exactly: BigInt(Int.max)) == Int.max)
		#expect(UInt(exactly: BigInt(UInt.max)) == UInt.max)
		#expect(Int8(exactly: BigInt(-128)) == -128)
		#expect(UInt8(exactly: BigInt(0)) == 0)
	}

	@Test func 範囲外ならexactlyはnil() {
		#expect(Int(exactly: BigInt(Int.max) + 1) == nil)
		#expect(Int(exactly: BigInt(Int.min) - 1) == nil)
		#expect(UInt(exactly: BigInt(-1)) == nil)
		#expect(UInt(exactly: BigInt(UInt.max) + 1) == nil)
		#expect(Int8(exactly: BigInt(128)) == nil)
	}

	@Test func truncatingIfNeededは下位ビットを残す() {
		#expect(UInt8(truncatingIfNeeded: BigInt(0x1FF)) == 0xFF)
		#expect(Int8(truncatingIfNeeded: BigInt(0x80)) == -128)
		#expect(UInt(truncatingIfNeeded: BigInt(-1)) == UInt.max)
		#expect(Int(truncatingIfNeeded: (BigInt(1) << 64) + 5) == 5)
	}

	@Test func clampingは範囲に丸める() {
		#expect(Int8(clamping: BigInt(1000)) == 127)
		#expect(Int8(clamping: BigInt(-1000)) == -128)
		#expect(UInt(clamping: BigInt(-1)) == 0)
		#expect(Int(clamping: BigInt(1) << 100) == Int.max)
		#expect(Int(clamping: BigInt(42)) == 42)
	}

	// MARK: 浮動小数点数へ

	@Test func Doubleへの変換は最近接の偶数に丸める() {
		// 2^53 + 1 は 2^53 と 2^53 + 2 の中間なので偶数側（2^53）へ
		#expect(Double((BigInt(1) << 53) + 1) == 0x1p53)
		// 2^53 + 3 は 2^53 + 2 と 2^53 + 4 の中間なので偶数側（2^53 + 4）へ
		#expect(Double((BigInt(1) << 53) + 3) == 0x1p53 + 4)
		#expect(Double(BigInt(-12345)) == -12345)
		#expect(Double(BigInt(0)) == 0)
	}

	@Test func 多ワードの値をDoubleに変換できる() {
		// 2^147 は 2^200 の仮数の最下位（2^148）のちょうど半分
		let tie: BigInt = (BigInt(1) << 200) + (BigInt(1) << 147)
		let aboveTie: BigInt = tie + 1

		#expect(Double(tie) == 0x1p200)
		#expect(Double(aboveTie) == 0x1p200 + 0x1p148)
		#expect(Double(-aboveTie) == -(0x1p200 + 0x1p148))
	}

	@Test func 大きすぎる値は無限大になる() {
		#expect(Double(BigInt(1) << 1024) == .infinity)
		#expect(Double(-(BigInt(1) << 1024)) == -.infinity)
	}

	@Test func Doubleのexactlyはちょうど表せるときだけ() {
		#expect(Double(exactly: BigInt(1) << 60) == 0x1p60)
		#expect(Double(exactly: (BigInt(1) << 60) + 1) == nil)
	}

}
