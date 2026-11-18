// MARK: 丸めとスケールの操作
extension BigDecimal {

	/// スケールを `newScale` にする。
	///
	/// スケールを減らすときは `rule` で丸める。増やすときは末尾に 0 を足す。
	/// 金額を通貨の桁に丸めるときに使う（Java の `setScale(n, mode)`）。
	public func rounded(
		scale newScale: Int,
		_ rule: RoundingRule,
	) -> BigDecimal {
		if newScale >= scale {
			return padded(toScale: newScale)
		}

		let divisor: BigInt = Self.powerOfTen(Self.scale(scale, minus: newScale))
		let (quotient, _) = unscaledValue.quotientAndRemainder(
			dividingBy: divisor,
			rounding: rule
		)
		return BigDecimal(unscaledValue: quotient, scale: newScale)
	}

	/// 桁数を `precision` 以下に丸める。桁数が収まっていれば変えない。
	/// `precision` が 0 以下なら実行時エラー。
	public func rounded(
		precision: Int,
		_ rule: RoundingRule,
	) -> BigDecimal {
		precondition(precision > 0, "BigDecimal precision must be positive")
		let digits: Int = self.precision

		if digits <= precision {
			return self
		}

		let dropped: Int = digits - precision
		let result: BigDecimal = rounded(
			scale: Self.scale(scale, minus: dropped),
			rule
		)

		// 繰り上がりで 1 桁増えたとき（999 → 1000）は、末尾の 0 を 1 つ落とす
		if result.precision > precision {
			return BigDecimal(
				unscaledValue: result.unscaledValue / Self.ten,
				scale: Self.scale(result.scale, minus: 1)
			)
		}

		return result
	}

	/// 丸めずにスケールを `newScale` にする。値が変わる（丸めが必要な）なら `nil`。
	public func settingScale(
		_ newScale: Int,
	) -> BigDecimal? {
		if newScale >= scale {
			return padded(toScale: newScale)
		}

		let divisor: BigInt = Self.powerOfTen(Self.scale(scale, minus: newScale))
		let (quotient, remainder) = unscaledValue.quotientAndRemainder(
			dividingBy: divisor
		)

		guard
			remainder.isZero
		else { return nil }

		return BigDecimal(unscaledValue: quotient, scale: newScale)
	}

	/// 末尾の 0 を取り除く（`600.0` → `6E+2`）。ゼロはスケール 0。
	public func normalized(
	) -> BigDecimal {
		if isZero {
			return BigDecimal(unscaledValue: 0, scale: 0)
		}

		var unscaled: BigInt = unscaledValue
		var scale: Int = self.scale

		while true {
			let (quotient, remainder) = unscaled.quotientAndRemainder(
				dividingBy: Self.ten
			)

			if !remainder.isZero {
				break
			}

			unscaled = quotient
			scale = Self.scale(scale, minus: 1)
		}

		return BigDecimal(unscaledValue: unscaled, scale: scale)
	}

	/// 整数部（0 方向に切り捨て）。スケールが正なら 0 にし、そうでなければそのまま。
	public var integerPart: BigDecimal {
		if scale <= 0 {
			return self
		}
		return BigDecimal(
			unscaledValue: unscaledValue / Self.powerOfTen(scale),
			scale: 0
		)
	}

	/// 小数部。符号は元の値と同じで、スケールを保つ。
	/// スケールが 0 以下ならスケール 0 のゼロ。
	public var fractionalPart: BigDecimal {
		if scale <= 0 {
			return BigDecimal(unscaledValue: 0, scale: 0)
		}
		return BigDecimal(
			unscaledValue: unscaledValue % Self.powerOfTen(scale),
			scale: scale
		)
	}

	/// 末尾に 0 を足してスケールを `newScale`（今のスケール以上）にする。
	internal func padded(
		toScale newScale: Int,
	) -> BigDecimal {
		if newScale == scale {
			return self
		}

		let factor: BigInt = Self.powerOfTen(Self.scale(newScale, minus: scale))
		return BigDecimal(unscaledValue: unscaledValue * factor, scale: newScale)
	}

}
