@testable import BigInt
import UnitTesting


/// Int に収まる範囲では、BigInt の演算結果は Int と同じになる。
@Suite struct BigIntとIntの演算結果は一致する {

	private let values: [Int] = Array(stride(from: -300, through: 300, by: 7))
		+ [Int.min / 2, Int.max / 2, -1, 0, 1]

	@Test func 加減乗算() {
		for a in values {
			for b in values {
				#expect(BigInt(a) + BigInt(b) == BigInt(a + b))
				#expect(BigInt(a) - BigInt(b) == BigInt(a - b))

				if a.magnitude < 1 << 31 && b.magnitude < 1 << 31 {
					#expect(BigInt(a) * BigInt(b) == BigInt(a * b))
				}
			}
		}
	}

	@Test func 除算と剰余() {
		for a in values {
			for b in values where b != 0 {
				#expect(BigInt(a) / BigInt(b) == BigInt(a / b))
				#expect(BigInt(a) % BigInt(b) == BigInt(a % b))
			}
		}
	}

	@Test func 比較() {
		for a in values {
			for b in values {
				#expect((BigInt(a) < BigInt(b)) == (a < b))
				#expect((BigInt(a) == BigInt(b)) == (a == b))
			}
		}
	}

	@Test func ビット演算() {
		for a in values {
			for b in values {
				#expect(BigInt(a) & BigInt(b) == BigInt(a & b))
				#expect(BigInt(a) | BigInt(b) == BigInt(a | b))
				#expect(BigInt(a) ^ BigInt(b) == BigInt(a ^ b))
			}

			#expect(~BigInt(a) == BigInt(~a))
		}
	}

	@Test func シフト() {
		for a in values {
			for shift in -10 ... 10 {
				// Int の左シフト（負の量の右シフトを含む）は上位ビットがあふれる
				if a.magnitude < 1 << 50 || shift >= 0 {
					#expect(BigInt(a) >> shift == BigInt(a >> shift))
				}

				if a.magnitude < 1 << 50 || shift <= 0 {
					#expect(BigInt(a) << shift == BigInt(a << shift))
				}
			}
		}
	}

	@Test func 文字列() {
		for a in values {
			for radix in [2, 8, 10, 16, 36] {
				#expect(String(BigInt(a), radix: radix) == String(a, radix: radix))
				#expect(BigInt(String(a, radix: radix), radix: radix) == BigInt(a))
			}
		}
	}

	@Test func 整数型への変換() {
		for a in values {
			#expect(Int(exactly: BigInt(a)) == a)
			#expect(Int8(exactly: BigInt(a)) == Int8(exactly: a))
			#expect(UInt16(clamping: BigInt(a)) == UInt16(clamping: a))
			#expect(Int16(truncatingIfNeeded: BigInt(a)) == Int16(truncatingIfNeeded: a))
			#expect(BigInt(a).trailingZeroBitCount == (a == 0 ? 1 : a.trailingZeroBitCount))
			#expect(BigInt(a).signum() == BigInt(a.signum()))
		}
	}

}
