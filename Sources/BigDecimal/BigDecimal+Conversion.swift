// MARK: 整数からの変換
extension BigDecimal {

	/// スケール 0。
	public init<T: BinaryInteger>(
		_ value: T,
	) {
		self.init(unscaledValue: BigInt(value), scale: 0)
	}

}


// MARK: 整数への変換
extension BigDecimal {

	/// 整数に丸める（Java の `toBigInteger` は `.towardZero`）。
	public func bigInt(
		rounding rule: RoundingRule,
	) -> BigInt {
		if scale <= 0 {
			return unscaledValue * Self.powerOfTen(-scale)
		}
		return unscaledValue.quotientAndRemainder(
			dividingBy: Self.powerOfTen(scale),
			rounding: rule
		).quotient
	}

	/// 小数部が 0 なら整数、そうでなければ `nil`。
	internal var exactBigInt: BigInt? {
		if scale <= 0 {
			return unscaledValue * Self.powerOfTen(-scale)
		}

		let (quotient, remainder) = unscaledValue.quotientAndRemainder(
			dividingBy: Self.powerOfTen(scale)
		)
		return remainder.isZero ? quotient : nil
	}

}
extension BinaryInteger {

	/// 小数部が 0 で、この型の範囲に収まるときだけ作る。
	public init?(
		exactly value: BigDecimal,
	) {
		guard
			let integer = value.exactBigInt
		else { return nil }

		self.init(exactly: integer)
	}

}


// MARK: 浮動小数点数からの変換
extension BigDecimal {

	/// 2 進の値をそのまま 10 進に展開する（`0.1` →
	/// `0.1000000000000000055511151231257827021181583404541015625`）。
	/// 末尾に 0 を持たない最小のスケールになる。NaN・無限大は `nil`。
	public init?<T: BinaryFloatingPoint>(
		exactly value: T,
	) {
		guard
			value.isFinite
		else { return nil }

		if value == 0 {
			self.init(unscaledValue: 0, scale: 0)
			return
		}

		// |value| = significand × 2^exponent（significand は整数）
		let magnitude: T = value.magnitude
		var significand: BigInt = BigInt(magnitude.significandBitPattern)
		var exponent: Int

		if magnitude.isNormal {
			significand |= BigInt(1) << T.significandBitCount
			exponent = Int(magnitude.exponent) - T.significandBitCount
		}
		else {
			exponent = Int(T.leastNormalMagnitude.exponent) - T.significandBitCount
		}

		let trailingZeros: Int = significand.trailingZeroBitCount
		significand >>= trailingZeros
		exponent += trailingZeros

		// 2^-k = 5^k × 10^-k
		let unscaled: BigInt = exponent >= 0
			? significand << exponent
			: significand * BigInt(5).power(-exponent)
		self.init(
			unscaledValue: value < 0 ? -unscaled : unscaled,
			scale: Swift.max(-exponent, 0)
		)
	}

	/// 最短の 10 進表記（`description` と同じ桁）から作る（`0.1` → `0.1`）。
	/// NaN・無限大は `nil`。
	public init?<T: BinaryFloatingPoint & LosslessStringConvertible>(
		roundTripping value: T,
	) {
		guard
			value.isFinite
		else { return nil }

		self.init(value.description)
	}

}


// MARK: 浮動小数点数への変換
extension BigDecimal {

	/// 最も近い `Double`（ちょうど中間なら偶数）。大きすぎれば無限大。
	internal var nearestDouble: Double {
		if isZero {
			return 0
		}

		let isNegative: Bool = unscaledValue < 0
		let adjusted: Int = adjustedExponent

		// 10^309 以上は無限大、10^-324 未満は 0 に丸まる
		if adjusted > 309 {
			return isNegative ? -.infinity : .infinity
		}

		if adjusted < -325 {
			return isNegative ? -0.0 : 0.0
		}

		if scale <= 0 {
			return Double(unscaledValue * Self.powerOfTen(-scale))
		}

		// |value| × 2^k を偶数丸めで整数にし、53 ビットになる k を探す。
		// 非正規化数の範囲では k を 1074 で止める
		let numerator: BigInt = unscaledValue.magnitude
		let denominator: BigInt = Self.powerOfTen(scale)
		let maximumShift: Int = 1074
		var shift: Int = Swift.min(
			52 - (numerator.bitWidth - denominator.bitWidth),
			maximumShift
		)

		while true {
			let quotient: BigInt = shift >= 0
				? (numerator << shift).quotientAndRemainder(
					dividingBy: denominator,
					rounding: .toNearestOrEven
				).quotient
				: numerator.quotientAndRemainder(
					dividingBy: denominator << -shift,
					rounding: .toNearestOrEven
				).quotient
			let bits: Int = quotient.bitWidth - 1

			if bits > 53 {
				shift -= 1
				continue
			}

			if bits < 53 && shift < maximumShift {
				shift += 1
				continue
			}

			let result: Double = Double(
				sign: .plus,
				exponent: -shift,
				significand: Double(quotient)
			)
			return isNegative ? -result : result
		}
	}

}
extension Double {

	/// 最も近い `Double`（ちょうど中間なら偶数）。大きすぎれば無限大。
	public init(
		_ value: BigDecimal,
	) {
		self = value.nearestDouble
	}

	/// ちょうど表せるときだけ作る。
	public init?(
		exactly value: BigDecimal,
	) {
		let nearest: Double = value.nearestDouble

		guard
			nearest.isFinite,
			let back = BigDecimal(exactly: nearest),
			back == value
		else { return nil }

		self = nearest
	}

}
