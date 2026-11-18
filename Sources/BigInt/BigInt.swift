/// 桁数に上限のない符号付き整数。
///
/// 値は符号と絶対値で持つ。絶対値は `UInt` のワード列で、下位のワードが先頭。
/// 整数リテラルに `StaticBigInt` を使うため、利用できる OS に下限がある。
public struct BigInt: Sendable {

	/// 負の数なら `true`。ゼロは常に `false`。
	internal let isNegative: Bool

	/// 絶対値のワード列。下位のワードが先頭で、上位に 0 のワードを残さない。
	/// ゼロは空。
	internal let limbs: [UInt]

	/// 符号と絶対値のワード列（下位が先頭）から、不変条件を満たすように正規化して作る。
	///
	/// 内部の表し方に依存するため、安定した API ではない。テストなどで使う。
	/// ワードの幅は環境の `UInt` に依存する。
	public init(
		_isNegative isNegative: Bool,
		limbs: [UInt],
	) {
		var limbs: [UInt] = limbs
		Limbs.normalize(&limbs)
		self.limbs = limbs
		self.isNegative = isNegative && !limbs.isEmpty
	}

	/// ゼロ。
	internal static let zeroValue: BigInt = .init(_isNegative: false, limbs: [])

	/// 1。
	internal static let oneValue: BigInt = .init(_isNegative: false, limbs: [1])

	/// ゼロなら `true`。
	public var isZero: Bool {
		limbs.isEmpty
	}

}


// MARK: Equatable / Hashable
extension BigInt: Hashable {

	public static func == (
		lhs: BigInt,
		rhs: BigInt,
	) -> Bool {
		lhs.isNegative == rhs.isNegative && lhs.limbs == rhs.limbs
	}

	public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(isNegative)
		hasher.combine(limbs)
	}

}


// MARK: Comparable
extension BigInt: Comparable {

	public static func < (
		lhs: BigInt,
		rhs: BigInt,
	) -> Bool {
		switch (lhs.isNegative, rhs.isNegative) {
			case (false, true):
				return false
			case (true, false):
				return true
			case (false, false):
				return Limbs.compare(lhs.limbs, rhs.limbs) < 0
			case (true, true):
				return Limbs.compare(rhs.limbs, lhs.limbs) < 0
		}
	}

}


// MARK: CustomDebugStringConvertible
extension BigInt: CustomDebugStringConvertible {

	public var debugDescription: String {
		description
	}

}
