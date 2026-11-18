// MARK: 除算


/// `/` 演算子は持たない。割り切れない除算の丸めを、必ず利用者に指示させるため。
extension BigDecimal {

	/// 結果のスケールを `scale` にして、`rule` で丸めた商。
	/// 0 で割ると実行時エラー（Java の `divide(d, scale, mode)`）。
	public func divided(
		by divisor: BigDecimal,
		scale: Int,
		rounding rule: RoundingRule,
	) -> BigDecimal {
		dividedReportingExactness(by: divisor, scale: scale, rounding: rule).result
	}

	/// 結果の桁数を `precision` 以下にして、`rule` で丸めた商。
	///
	/// 割り切れるときは、スケールを「被除数のスケール − 除数のスケール」に
	/// できるだけ近づける（Java の `divide(d, MathContext)`、GDA の divide）。
	/// 0 で割るか、`precision` が 0 以下なら実行時エラー。
	public func divided(
		by divisor: BigDecimal,
		precision: Int,
		rounding rule: RoundingRule,
	) -> BigDecimal {
		dividedReportingExactness(
			by: divisor,
			precision: precision,
			rounding: rule
		).result
	}

	/// 厳密な商。割り切れなければ `nil`。0 で割ると実行時エラー。
	///
	/// スケールは「被除数のスケール − 除数のスケール」。それで表せなければ、
	/// 表せる最小のスケール（Java の `divide(d)`）。
	public func dividedExactly(
		by divisor: BigDecimal,
	) -> BigDecimal? {
		precondition(!divisor.isZero, "Division by zero")
		let preferredScale: Int = Self.scale(scale, minus: divisor.scale)

		if isZero {
			return BigDecimal(unscaledValue: 0, scale: preferredScale)
		}

		// 割り切れるなら、商の桁数は被除数の桁数 + ⌈10 × 除数の桁数 ÷ 3⌉ 以下
		let maximumPrecision: Int = precision + (10 * divisor.precision + 2) / 3
		let (result, isExact) = dividedReportingExactness(
			by: divisor,
			precision: maximumPrecision,
			rounding: .towardZero
		)

		guard
			isExact
		else { return nil }

		if result.scale < preferredScale {
			return result.padded(toScale: preferredScale)
		}

		return result
	}

	/// 整数部の商（0 方向に切り捨て、スケール 0）と剰余（被除数と同じ符号）。
	/// 剰余のスケールは、被除数と除数のスケールの大きいほう。0 で割ると実行時エラー。
	public func quotientAndRemainder(
		dividingBy divisor: BigDecimal,
	) -> (quotient: BigDecimal, remainder: BigDecimal) {
		let quotient: BigDecimal = divided(
			by: divisor,
			scale: 0,
			rounding: .towardZero
		)
		return (quotient, self - quotient * divisor)
	}

	/// 被除数と同じ符号の剰余（`quotientAndRemainder(dividingBy:)` の剰余）。
	public func truncatingRemainder(
		dividingBy divisor: BigDecimal,
	) -> BigDecimal {
		quotientAndRemainder(dividingBy: divisor).remainder
	}

}


// MARK: 内部の除算
extension BigDecimal {

	/// スケールを指定した除算と、丸めずに済んだか。
	internal func dividedReportingExactness(
		by divisor: BigDecimal,
		scale newScale: Int,
		rounding rule: RoundingRule,
	) -> (result: BigDecimal, isExact: Bool) {
		precondition(!divisor.isZero, "Division by zero")

		// self ÷ divisor × 10^newScale
		//   = unscaled × 10^(newScale − scale + divisor.scale) ÷ divisor.unscaled
		let shift: Int = Self.scale(
			Self.scale(newScale, minus: scale),
			plus: divisor.scale
		)
		var numerator: BigInt = unscaledValue
		var denominator: BigInt = divisor.unscaledValue

		if shift >= 0 {
			numerator *= Self.powerOfTen(shift)
		}
		else {
			denominator *= Self.powerOfTen(-shift)
		}

		let (quotient, remainder) = numerator.quotientAndRemainder(
			dividingBy: denominator,
			rounding: rule
		)
		return (
			BigDecimal(unscaledValue: quotient, scale: newScale),
			remainder.isZero
		)
	}

	/// 桁数を指定した除算と、丸めずに済んだか。
	internal func dividedReportingExactness(
		by divisor: BigDecimal,
		precision: Int,
		rounding rule: RoundingRule,
	) -> (result: BigDecimal, isExact: Bool) {
		precondition(precision > 0, "BigDecimal precision must be positive")
		precondition(!divisor.isZero, "Division by zero")
		let preferredScale: Int = Self.scale(scale, minus: divisor.scale)

		if isZero {
			return (BigDecimal(unscaledValue: 0, scale: preferredScale), true)
		}

		// 商が precision 桁以上（多くとも precision + 1 桁）になるスケールで、
		// いったん切り捨てて桁数を調べる
		let adjustedDifference: Int = Self.scale(
			adjustedExponent,
			minus: divisor.adjustedExponent
		)
		let estimatedScale: Int = Self.scale(precision, minus: adjustedDifference)
		let estimate: BigDecimal = dividedReportingExactness(
			by: divisor,
			scale: estimatedScale,
			rounding: .towardZero
		).result
		let excess: Int = estimate.precision - precision

		// ちょうど precision 桁になるスケールで丸める
		var (result, isExact) = dividedReportingExactness(
			by: divisor,
			scale: Self.scale(estimatedScale, minus: excess),
			rounding: rule
		)

		// 繰り上がりで 1 桁増えたとき（999 → 1000）は、末尾の 0 を 1 つ落とす
		if result.precision > precision {
			result = BigDecimal(
				unscaledValue: result.unscaledValue / Self.ten,
				scale: Self.scale(result.scale, minus: 1)
			)
		}

		// 割り切れたら、望ましいスケールまで末尾の 0 を取り除く
		if isExact {
			result = result.strippingTrailingZeros(downTo: preferredScale)
		}

		return (result, isExact)
	}

	/// スケールが `minimumScale` より大きい間、末尾の 0 を取り除く。
	internal func strippingTrailingZeros(
		downTo minimumScale: Int,
	) -> BigDecimal {
		var unscaled: BigInt = unscaledValue
		var scale: Int = self.scale

		while scale > minimumScale && !unscaled.isZero {
			let (quotient, remainder) = unscaled.quotientAndRemainder(
				dividingBy: Self.ten
			)

			if !remainder.isZero {
				break
			}

			unscaled = quotient
			scale -= 1
		}

		return BigDecimal(unscaledValue: unscaled, scale: scale)
	}

}
