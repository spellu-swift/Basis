// MARK: ビットの情報
extension BigInt {

	/// 2 の補数で表したときの最小のビット数（符号ビットを含む）。
	/// 0 は 1、255 は 9、-1 は 1、-8 は 4。
	public var bitWidth: Int {
		let bitLength: Int = Limbs.bitLength(limbs)

		if bitLength == 0 {
			return 1
		}

		// 負の 2 の冪（-1, -2, -4, ...）は、絶対値のビット長で表せる
		if isNegative && Limbs.isPowerOfTwo(limbs) {
			return bitLength
		}

		return bitLength + 1
	}

	/// 末尾の 0 のビットの数。0 は `bitWidth`（つまり 1）。
	public var trailingZeroBitCount: Int {
		if isZero {
			return bitWidth
		}
		return Limbs.trailingZeroBitCount(limbs)
	}

	/// 符号拡張した 2 の補数のワード列（下位が先頭）。
	/// `bitWidth` を収められる最小のワード数。
	public var words: [UInt] {
		let count: Int = (bitWidth + Limbs.wordBitWidth - 1)
			/ Limbs.wordBitWidth
		return twosComplement(count: count)
	}

}


// MARK: ビット演算
extension BigInt {

	/// 負の数を無限長の 2 の補数とみなして、ワードごとに演算する。
	private static func bitwise(
		_ lhs: BigInt,
		_ rhs: BigInt,
		_ operation: (UInt, UInt) -> UInt,
	) -> BigInt {
		let count: Int = Swift.max(lhs.limbs.count, rhs.limbs.count) + 1
		let left: [UInt] = lhs.twosComplement(count: count)
		let right: [UInt] = rhs.twosComplement(count: count)
		return BigInt(words: zip(left, right).map(operation))
	}

	/// ビット反転。`~x == -x - 1`。
	public static prefix func ~ (
		operand: BigInt,
	) -> BigInt {
		-operand - .oneValue
	}

	public static func & (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		bitwise(lhs, rhs, &)
	}

	public static func | (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		bitwise(lhs, rhs, |)
	}

	public static func ^ (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		bitwise(lhs, rhs, ^)
	}

	public static func &= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs & rhs
	}

	public static func |= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs | rhs
	}

	public static func ^= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs ^ rhs
	}

}


// MARK: シフト
extension BigInt {

	/// 左シフト。負のシフト量は右シフトになる。
	public static func <<= <RHS: BinaryInteger>(
		lhs: inout BigInt,
		rhs: RHS,
	) {
		lhs = lhs.shifted(left: rhs)
	}

	/// 算術右シフト（負の無限大方向）。負のシフト量は左シフトになる。
	public static func >>= <RHS: BinaryInteger>(
		lhs: inout BigInt,
		rhs: RHS,
	) {
		lhs = lhs.shifted(right: rhs)
	}

	private func shifted<RHS: BinaryInteger>(
		left amount: RHS,
	) -> BigInt {
		if let bits = Int(exactly: amount), bits != .min {
			return bits >= 0 ? shiftedLeft(bits) : shiftedRight(-bits)
		}

		// Int に収まらないシフト量
		if amount < 0 {
			return isNegative ? -.oneValue : .zeroValue
		}

		precondition(isZero, "BigInt shift amount is too large")
		return self
	}

	private func shifted<RHS: BinaryInteger>(
		right amount: RHS,
	) -> BigInt {
		if let bits = Int(exactly: amount), bits != .min {
			return bits >= 0 ? shiftedRight(bits) : shiftedLeft(-bits)
		}

		// Int に収まらないシフト量
		if amount > 0 {
			return isNegative ? -.oneValue : .zeroValue
		}

		precondition(isZero, "BigInt shift amount is too large")
		return self
	}

	private func shiftedLeft(
		_ bits: Int,
	) -> BigInt {
		BigInt(_isNegative: isNegative, limbs: Limbs.shiftLeft(limbs, by: bits))
	}

	private func shiftedRight(
		_ bits: Int,
	) -> BigInt {
		if !isNegative {
			return BigInt(
				_isNegative: false,
				limbs: Limbs.shiftRight(limbs, by: bits)
			)
		}

		// 負の数は負の無限大方向に丸める：-(((|x| - 1) >> bits) + 1)
		let decremented: [UInt] = Limbs.subtract(limbs, [1])
		var shifted: [UInt] = Limbs.shiftRight(decremented, by: bits)
		shifted = Limbs.add(shifted, [1])
		return BigInt(_isNegative: true, limbs: shifted)
	}

}
