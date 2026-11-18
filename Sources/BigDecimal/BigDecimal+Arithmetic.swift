// MARK: SignedNumeric
extension BigDecimal: SignedNumeric {

	public typealias Magnitude = BigDecimal

	public typealias IntegerLiteralType = StaticBigInt

	/// スケール 0。64 ビットを超える整数リテラルも書ける。
	public init(
		integerLiteral value: StaticBigInt,
	) {
		self.init(unscaledValue: BigInt(integerLiteral: value), scale: 0)
	}

	/// 整数はすべて表せるので、常に成功する。スケール 0。
	public init?<T: BinaryInteger>(
		exactly source: T,
	) {
		self.init(source)
	}

	/// 絶対値。スケールを保つ。
	public var magnitude: BigDecimal {
		BigDecimal(unscaledValue: unscaledValue.magnitude, scale: scale)
	}

}


// MARK: 加減乗算
extension BigDecimal {

	/// 厳密な和。スケールは大きいほう。
	public static func + (
		lhs: BigDecimal,
		rhs: BigDecimal,
	) -> BigDecimal {
		let (left, right, scale) = aligned(lhs, rhs)
		return BigDecimal(unscaledValue: left + right, scale: scale)
	}

	/// 厳密な差。スケールは大きいほう。
	public static func - (
		lhs: BigDecimal,
		rhs: BigDecimal,
	) -> BigDecimal {
		let (left, right, scale) = aligned(lhs, rhs)
		return BigDecimal(unscaledValue: left - right, scale: scale)
	}

	/// 厳密な積。スケールは和。
	public static func * (
		lhs: BigDecimal,
		rhs: BigDecimal,
	) -> BigDecimal {
		BigDecimal(
			unscaledValue: lhs.unscaledValue * rhs.unscaledValue,
			scale: scale(lhs.scale, plus: rhs.scale)
		)
	}

	public static prefix func - (
		operand: BigDecimal,
	) -> BigDecimal {
		BigDecimal(unscaledValue: -operand.unscaledValue, scale: operand.scale)
	}

	public static func += (
		lhs: inout BigDecimal,
		rhs: BigDecimal,
	) {
		lhs = lhs + rhs
	}

	public static func -= (
		lhs: inout BigDecimal,
		rhs: BigDecimal,
	) {
		lhs = lhs - rhs
	}

	public static func *= (
		lhs: inout BigDecimal,
		rhs: BigDecimal,
	) {
		lhs = lhs * rhs
	}

	public mutating func negate(
	) {
		self = -self
	}

}


// MARK: 符号・桁
extension BigDecimal {

	/// 負なら -1、ゼロなら 0、正なら 1。
	public func signum(
	) -> Int {
		if unscaledValue.isZero {
			return 0
		}
		return unscaledValue < 0 ? -1 : 1
	}

	/// ゼロなら `true`（スケールによらない）。
	public var isZero: Bool {
		unscaledValue.isZero
	}

	/// 小数部が 0 なら `true`（`2.00` も真）。
	public var isInteger: Bool {
		if scale <= 0 {
			return true
		}
		return (unscaledValue % Self.powerOfTen(scale)).isZero
	}

	/// 非スケール値の桁数。ゼロは 1。
	public var precision: Int {
		unscaledValue.decimalDigitCount
	}

	/// 10 の `n` 乗を掛ける。スケールが `n` 減るだけで、丸めない。
	public func multipliedByPowerOfTen(
		_ n: Int,
	) -> BigDecimal {
		BigDecimal(unscaledValue: unscaledValue, scale: Self.scale(scale, minus: n))
	}

}
