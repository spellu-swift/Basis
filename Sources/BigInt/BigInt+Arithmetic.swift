// MARK: SignedInteger
extension BigInt: SignedInteger {

	public typealias Magnitude = BigInt

	public typealias Words = [UInt]

	public typealias Stride = BigInt


	/// 絶対値。
	public var magnitude: BigInt {
		BigInt(_isNegative: false, limbs: limbs)
	}

	/// 負なら -1、ゼロなら 0、正なら 1。
	public func signum(
	) -> BigInt {
		if isZero {
			return .zeroValue
		}
		return isNegative ? -.oneValue : .oneValue
	}

}


// MARK: 加減算
extension BigInt {

	public static func + (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		if lhs.isNegative == rhs.isNegative {
			return BigInt(
				_isNegative: lhs.isNegative,
				limbs: Limbs.add(lhs.limbs, rhs.limbs)
			)
		}

		// 符号が違うときは、絶対値の大きいほうから小さいほうを引く
		switch Limbs.compare(lhs.limbs, rhs.limbs) {
			case 0:
				return .zeroValue
			case 1:
				return BigInt(
					_isNegative: lhs.isNegative,
					limbs: Limbs.subtract(lhs.limbs, rhs.limbs)
				)
			default:
				return BigInt(
					_isNegative: rhs.isNegative,
					limbs: Limbs.subtract(rhs.limbs, lhs.limbs)
				)
		}
	}

	public static func - (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		lhs + -rhs
	}

	public static prefix func - (
		operand: BigInt,
	) -> BigInt {
		BigInt(_isNegative: !operand.isNegative, limbs: operand.limbs)
	}

	public static func += (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs + rhs
	}

	public static func -= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs - rhs
	}

	public mutating func negate(
	) {
		self = -self
	}

}


// MARK: 乗除算
extension BigInt {

	public static func * (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		BigInt(
			_isNegative: lhs.isNegative != rhs.isNegative,
			limbs: Limbs.multiply(lhs.limbs, rhs.limbs)
		)
	}

	public static func *= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs * rhs
	}

	/// 商と剰余。商は 0 方向に切り捨て、剰余は被除数と同じ符号。
	/// 0 で割ると実行時エラー。
	public func quotientAndRemainder(
		dividingBy divisor: BigInt,
	) -> (quotient: BigInt, remainder: BigInt) {
		precondition(!divisor.isZero, "Division by zero")
		let (quotient, remainder) = Limbs.divide(limbs, by: divisor.limbs)
		return (
			BigInt(
				_isNegative: isNegative != divisor.isNegative,
				limbs: quotient
			),
			BigInt(_isNegative: isNegative, limbs: remainder)
		)
	}

	/// 0 方向に切り捨てた商。0 で割ると実行時エラー。
	public static func / (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		lhs.quotientAndRemainder(dividingBy: rhs).quotient
	}

	/// 被除数と同じ符号の剰余。0 で割ると実行時エラー。
	public static func % (
		lhs: BigInt,
		rhs: BigInt,
	) -> BigInt {
		lhs.quotientAndRemainder(dividingBy: rhs).remainder
	}

	public static func /= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs / rhs
	}

	public static func %= (
		lhs: inout BigInt,
		rhs: BigInt,
	) {
		lhs = lhs % rhs
	}

}


// MARK: Strideable
extension BigInt {

	public func distance(
		to other: BigInt,
	) -> BigInt {
		other - self
	}

	public func advanced(
		by n: BigInt,
	) -> BigInt {
		self + n
	}

}
