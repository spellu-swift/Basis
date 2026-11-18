@_exported import BigInt


/// 10進の任意精度の数。金額の計算に使う。
///
/// 値は `unscaledValue × 10^(−scale)`。末尾の 0 を保持する
/// （`1.50` は `[150, 2]`、`1.5` は `[15, 1]`）。
///
/// - 等価性と順序は値で判定する（`1.0 == 1.00`）。表現まで同じかは
///   `isIdentical(to:)` で調べる。
/// - 加減乗算は厳密。結果のスケールは、加減算では大きいほう、乗算では和。
/// - 割り切れない除算を黙って丸めないため、`/` 演算子を持たない。
///   `divided(by:scale:rounding:)` などで丸め方を指定する。
/// - NaN・無限大・符号付きゼロは持たない。
public struct BigDecimal: Sendable {

	/// 非スケール値（係数）。符号つき。
	public let unscaledValue: BigInt

	/// 小数点以下の桁数。負なら 10 の冪を掛ける。
	public let scale: Int

	public init(
		unscaledValue: BigInt,
		scale: Int,
	) {
		self.unscaledValue = unscaledValue
		self.scale = scale
	}

}


// MARK: 内部の補助
extension BigDecimal {

	internal static let ten: BigInt = 10

	/// 10 の `exponent` 乗。
	internal static func powerOfTen(
		_ exponent: Int,
	) -> BigInt {
		ten.power(exponent)
	}

	/// スケールの和。あふれたら実行時エラー。
	internal static func scale(
		_ lhs: Int,
		plus rhs: Int,
	) -> Int {
		let (result, overflow) = lhs.addingReportingOverflow(rhs)
		precondition(!overflow, "BigDecimal scale overflow")
		return result
	}

	/// スケールの差。あふれたら実行時エラー。
	internal static func scale(
		_ lhs: Int,
		minus rhs: Int,
	) -> Int {
		let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
		precondition(!overflow, "BigDecimal scale overflow")
		return result
	}

	/// 調整済み指数（最上位の桁の位）。`precision - 1 - scale`。
	/// ゼロでないときに使う。
	internal var adjustedExponent: Int {
		Self.scale(precision - 1, minus: scale)
	}

	/// 2 つの値を同じスケールに揃えた非スケール値。
	internal static func aligned(
		_ lhs: BigDecimal,
		_ rhs: BigDecimal,
	) -> (lhs: BigInt, rhs: BigInt, scale: Int) {
		if lhs.scale == rhs.scale {
			return (lhs.unscaledValue, rhs.unscaledValue, lhs.scale)
		}

		if lhs.scale < rhs.scale {
			let factor: BigInt = powerOfTen(scale(rhs.scale, minus: lhs.scale))
			return (lhs.unscaledValue * factor, rhs.unscaledValue, rhs.scale)
		}

		let factor: BigInt = powerOfTen(scale(lhs.scale, minus: rhs.scale))
		return (lhs.unscaledValue, rhs.unscaledValue * factor, lhs.scale)
	}

	/// 値の比較。`lhs < rhs` なら -1、等しければ 0、`lhs > rhs` なら 1。
	internal static func compare(
		_ lhs: BigDecimal,
		_ rhs: BigDecimal,
	) -> Int {
		let lhsSign: Int = lhs.signum()
		let rhsSign: Int = rhs.signum()

		if lhsSign != rhsSign {
			return lhsSign < rhsSign ? -1 : 1
		}

		if lhsSign == 0 {
			return 0
		}

		// 最上位の桁の位が違えば、揃えずに決まる（スケールが大きく違っても安い）
		let lhsAdjusted: Int = lhs.adjustedExponent
		let rhsAdjusted: Int = rhs.adjustedExponent

		if lhsAdjusted != rhsAdjusted {
			let order: Int = lhsAdjusted < rhsAdjusted ? -1 : 1
			return lhsSign > 0 ? order : -order
		}

		let (left, right, _) = aligned(lhs, rhs)

		if left == right {
			return 0
		}
		return left < right ? -1 : 1
	}

}


// MARK: Equatable / Hashable
extension BigDecimal: Hashable {

	/// 値が等しければ真（`1.0 == 1.00`）。
	public static func == (
		lhs: BigDecimal,
		rhs: BigDecimal,
	) -> Bool {
		compare(lhs, rhs) == 0
	}

	/// 末尾の 0 を取り除いた形で計算するので、等しい値はハッシュも等しい。
	public func hash(
		into hasher: inout Hasher,
	) {
		let reduced: BigDecimal = normalized()
		hasher.combine(reduced.unscaledValue)
		hasher.combine(reduced.scale)
	}

	/// 値とスケールがともに等しければ真（`1.0` と `1.00` は偽）。
	public func isIdentical(
		to other: BigDecimal,
	) -> Bool {
		unscaledValue == other.unscaledValue && scale == other.scale
	}

}


// MARK: Comparable
extension BigDecimal: Comparable {

	public static func < (
		lhs: BigDecimal,
		rhs: BigDecimal,
	) -> Bool {
		compare(lhs, rhs) < 0
	}

}


// MARK: CustomDebugStringConvertible
extension BigDecimal: CustomDebugStringConvertible {

	public var debugDescription: String {
		description
	}

}
