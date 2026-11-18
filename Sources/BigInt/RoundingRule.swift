/// 丸め方。`BigInt` の丸め方付きの除算と、`BigDecimal` の丸めで使う。
///
/// ケースの名前と意味は `FloatingPointRoundingRule` と同じで、
/// `toNearestOrTowardZero`（ちょうど半分を 0 に近いほうへ）が加わる。
///
/// | ケース | Java `RoundingMode` | C# `MidpointRounding` |
/// |---|---|---|
/// | `towardZero` | `DOWN` | `ToZero` |
/// | `awayFromZero` | `UP` | — |
/// | `up` | `CEILING` | `ToPositiveInfinity` |
/// | `down` | `FLOOR` | `ToNegativeInfinity` |
/// | `toNearestOrEven` | `HALF_EVEN` | `ToEven` |
/// | `toNearestOrAwayFromZero` | `HALF_UP` | `AwayFromZero` |
/// | `toNearestOrTowardZero` | `HALF_DOWN` | — |
public enum RoundingRule: Sendable, Hashable, CaseIterable {

	/// 0 に近づく方向（切り捨て）。
	case towardZero

	/// 0 から遠ざかる方向（切り上げ）。
	case awayFromZero

	/// 正の無限大方向（天井）。
	case up

	/// 負の無限大方向（床）。
	case down

	/// 最も近い値へ。ちょうど半分なら偶数へ（銀行丸め）。
	case toNearestOrEven

	/// 最も近い値へ。ちょうど半分なら 0 から遠ざかる方向へ（四捨五入）。
	case toNearestOrAwayFromZero

	/// 最も近い値へ。ちょうど半分なら 0 に近づく方向へ。
	case toNearestOrTowardZero

}


extension RoundingRule {

	/// `FloatingPointRoundingRule` の同じ意味のケース。
	/// 将来追加される未知のケースは実行時エラー。
	public init(
		_ rule: FloatingPointRoundingRule,
	) {
		switch rule {
			case .towardZero:
				self = .towardZero
			case .awayFromZero:
				self = .awayFromZero
			case .up:
				self = .up
			case .down:
				self = .down
			case .toNearestOrEven:
				self = .toNearestOrEven
			case .toNearestOrAwayFromZero:
				self = .toNearestOrAwayFromZero
			@unknown default:
				preconditionFailure("Unknown FloatingPointRoundingRule: \(rule)")
		}
	}

	/// 同じ意味の `FloatingPointRoundingRule`。
	/// `toNearestOrTowardZero` には当たるものがないので `nil`。
	public var floatingPointRoundingRule: FloatingPointRoundingRule? {
		switch self {
			case .towardZero:
				return .towardZero
			case .awayFromZero:
				return .awayFromZero
			case .up:
				return .up
			case .down:
				return .down
			case .toNearestOrEven:
				return .toNearestOrEven
			case .toNearestOrAwayFromZero:
				return .toNearestOrAwayFromZero
			case .toNearestOrTowardZero:
				return nil
		}
	}

}
