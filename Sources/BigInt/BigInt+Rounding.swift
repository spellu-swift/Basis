// MARK: 丸め方付きの除算
extension BigInt {

	/// 商を `rule` で整数に丸めた商と剰余。
	///
	/// 剰余は `self - quotient * divisor`。`.towardZero` なら
	/// `quotientAndRemainder(dividingBy:)` と同じ結果になる。
	/// `.down` なら Python の `//` と `%` と同じ結果になる。
	/// 0 で割ると実行時エラー。
	public func quotientAndRemainder(
		dividingBy divisor: BigInt,
		rounding rule: RoundingRule,
	) -> (quotient: BigInt, remainder: BigInt) {
		let (quotient, remainder) = quotientAndRemainder(dividingBy: divisor)

		if remainder.isZero {
			return (quotient, remainder)
		}

		// 真の商の符号（剰余が 0 でないので、商は 0 になりうるが真の商は 0 でない）
		let isNegativeQuotient: Bool = isNegative != divisor.isNegative

		if !Self.roundsAwayFromZero(
			rule,
			isNegative: isNegativeQuotient,
			isOdd: quotient.limbs.first.map { $0 & 1 == 1 } ?? false,
			halfComparison: Self.compareTwice(remainder, with: divisor)
		) {
			return (quotient, remainder)
		}

		// 0 から遠ざかる方向へ 1 動かす
		if isNegativeQuotient {
			return (quotient - .oneValue, remainder + divisor)
		}
		return (quotient + .oneValue, remainder - divisor)
	}

	/// `2 * |remainder|` と `|divisor|` の比較。
	/// 捨てる部分が半分より小さいなら -1、ちょうど半分なら 0、大きいなら 1。
	private static func compareTwice(
		_ remainder: BigInt,
		with divisor: BigInt,
	) -> Int {
		Limbs.compare(Limbs.shiftLeft(remainder.limbs, by: 1), divisor.limbs)
	}

	/// 切り捨てた値を 0 から遠ざかる方向へ 1 動かすか。
	///
	/// - Parameters:
	///   - isNegative: 真の値が負か。
	///   - isOdd: 切り捨てた値の最下位の桁が奇数か（偶数丸めで使う）。
	///   - halfComparison: 捨てる部分と半分との比較（-1、0、1）。
	internal static func roundsAwayFromZero(
		_ rule: RoundingRule,
		isNegative: Bool,
		isOdd: Bool,
		halfComparison: Int,
	) -> Bool {
		switch rule {
			case .towardZero:
				return false
			case .awayFromZero:
				return true
			case .up:
				return !isNegative
			case .down:
				return isNegative
			case .toNearestOrEven:
				return halfComparison > 0 || (halfComparison == 0 && isOdd)
			case .toNearestOrAwayFromZero:
				return halfComparison >= 0
			case .toNearestOrTowardZero:
				return halfComparison > 0
		}
	}

}
