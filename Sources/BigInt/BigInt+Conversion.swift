// MARK: 2 の補数
extension BigInt {

	/// 2 の補数のワード列（下位が先頭）から作る。``words``の逆変換。
	/// 最上位ワードの最上位ビットを符号とみなす。空のワード列は 0。
	///
	/// 正の数として作るときは、最上位ビットが立たないよう、上位に 0 のワードを足す。
	public init(
		words: [UInt],
	) {
		guard
			let top = words.last,
			top >> (Limbs.wordBitWidth - 1) == 1
		else {
			self.init(_isNegative: false, limbs: words)
			return
		}

		// 負の数：反転して 1 を足すと絶対値になる
		var magnitude: [UInt] = words.map { ~$0 }
		Limbs.increment(&magnitude)
		self.init(_isNegative: true, limbs: magnitude)
	}

	/// `count` ワードの幅の 2 の補数のワード列。
	/// `count` は絶対値のワード数より大きいこと。
	internal func twosComplement(
		count: Int,
	) -> [UInt] {
		var result: [UInt] = limbs
		result.append(
			contentsOf: repeatElement(0, count: count - limbs.count)
		)

		if isNegative {
			result = result.map { ~$0 }
			Limbs.increment(&result)
		}

		return result
	}

}


// MARK: 整数リテラル
extension BigInt {

	public typealias IntegerLiteralType = StaticBigInt

	public init(
		integerLiteral value: StaticBigInt,
	) {
		let count: Int = (value.bitWidth + Limbs.wordBitWidth - 1)
			/ Limbs.wordBitWidth
		let words: [UInt] = (0 ..< count).map { value[$0] }
		self.init(words: words)
	}

}


// MARK: 整数型からの変換
extension BigInt {

	public init<T: BinaryInteger>(
		_ source: T,
	) {
		if let value = source as? BigInt {
			self = value
			return
		}

		let words: [UInt] = Array(source.words)

		if T.isSigned {
			self.init(words: words)
		}
		else {
			self.init(_isNegative: false, limbs: words)
		}
	}

	/// 幅に上限がないので、常に成功する。
	public init?<T: BinaryInteger>(
		exactly source: T,
	) {
		self.init(source)
	}

	/// 幅に上限がないので、切り詰めは起きず、元の値と等しくなる。
	public init<T: BinaryInteger>(
		truncatingIfNeeded source: T,
	) {
		self.init(source)
	}

	/// 幅に上限がないので、丸めは起きず、元の値と等しくなる。
	public init<T: BinaryInteger>(
		clamping source: T,
	) {
		self.init(source)
	}

}


// MARK: 浮動小数点数からの変換
extension BigInt {

	/// 小数部を 0 方向に切り捨てる。NaN・無限大は実行時エラー。
	public init<T: BinaryFloatingPoint>(
		_ source: T,
	) {
		precondition(
			source.isFinite,
			"\(T.self) value cannot be converted to BigInt because it is either infinite or NaN"
		)
		let truncated: T = source.rounded(.towardZero)

		if truncated == 0 {
			self = .zeroValue
			return
		}

		// 整数部は正規化数なので、暗黙の先頭ビットを補う
		let significand: BigInt = BigInt(truncated.significandBitPattern)
			| (BigInt.oneValue << T.significandBitCount)
		let shift: Int = Int(truncated.exponent) - T.significandBitCount
		let magnitude: BigInt = shift >= 0
			? significand << shift
			: significand >> -shift
		self = truncated < 0 ? -magnitude : magnitude
	}

	/// 整数でちょうど表せるときだけ作る。NaN・無限大は `nil`。
	public init?<T: BinaryFloatingPoint>(
		exactly source: T,
	) {
		guard
			source.isFinite,
			source.rounded(.towardZero) == source
		else { return nil }

		self.init(source)
	}

}
