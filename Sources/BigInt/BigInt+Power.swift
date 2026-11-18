// MARK: 冪と10進の桁数
extension BigInt {

	/// `self` の `exponent` 乗。繰り返し二乗法で計算する。
	///
	/// `0.power(0)` は 1。負の指数は実行時エラー。
	public func power(
		_ exponent: Int,
	) -> BigInt {
		precondition(exponent >= 0, "BigInt.power: negative exponent")
		var result: BigInt = .oneValue
		var base: BigInt = self
		var rest: Int = exponent

		while rest > 0 {
			if rest & 1 == 1 {
				result *= base
			}

			rest >>= 1

			if rest > 0 {
				base *= base
			}
		}

		return result
	}

	/// 絶対値の10進の桁数。0 は 1。
	public var decimalDigitCount: Int {
		let bitLength: Int = Limbs.bitLength(limbs)

		if bitLength <= 1 {
			return 1
		}

		// 2^(bitLength - 1) の桁数から見積もり、10 の冪と比べて補正する
		let log10Of2: Double = 0.301029995663981195213738894724493026768189881462108541310
		var digits: Int = Int(Double(bitLength - 1) * log10Of2) + 1
		let ten: BigInt = 10
		let absolute: BigInt = magnitude

		while digits > 1 && absolute < ten.power(digits - 1) {
			digits -= 1
		}

		while absolute >= ten.power(digits) {
			digits += 1
		}

		return digits
	}

}
