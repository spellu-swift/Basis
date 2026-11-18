// MARK: 文字列からの生成
extension BigDecimal: LosslessStringConvertible {

	/// 文字列を解析する。書式は `[符号] 数字 [. 数字] [e|E [符号] 数字]`（Java・GDA と同じ）。
	///
	/// - 数字は 1 つ以上必要（`.5`、`5.` は可。`.` だけ、符号だけは不可）。
	/// - 前後の空白、`_`、`NaN`、`Infinity`、`0x` を含むと `nil`。
	/// - スケールは「小数部の桁数 − 指数」。`"1.50"` → `[150, 2]`、
	///   `"1E+3"` → `[1, -3]`。スケールが `Int` に収まらなければ `nil`。
	public init?<S: StringProtocol>(
		_ text: S,
	) {
		var bytes: ArraySlice<UInt8> = ArraySlice(text.utf8)
		var isNegative: Bool = false

		if let first = bytes.first, first == UInt8(ascii: "+") || first == UInt8(ascii: "-") {
			isNegative = first == UInt8(ascii: "-")
			bytes.removeFirst()
		}

		// 整数部と小数部の数字
		var digits: [UInt8] = []
		var fractionDigitCount: Int = 0

		while let byte = bytes.first, Self.isDigit(byte) {
			digits.append(byte)
			bytes.removeFirst()
		}

		if bytes.first == UInt8(ascii: ".") {
			bytes.removeFirst()

			while let byte = bytes.first, Self.isDigit(byte) {
				digits.append(byte)
				fractionDigitCount += 1
				bytes.removeFirst()
			}
		}

		if digits.isEmpty {
			return nil
		}

		// 指数（スケールが Int.min のときは指数が Int に収まらないので BigInt で読む）
		var exponent: BigInt = 0

		if let byte = bytes.first, byte == UInt8(ascii: "e") || byte == UInt8(ascii: "E") {
			bytes.removeFirst()
			guard
				let value = BigInt(String(decoding: bytes, as: UTF8.self))
			else { return nil }

			exponent = value
			bytes = []
		}

		if !bytes.isEmpty {
			return nil
		}

		guard
			let scale = Int(exactly: BigInt(fractionDigitCount) - exponent),
			let magnitude = BigInt(String(decoding: digits, as: UTF8.self))
		else { return nil }

		self.init(
			unscaledValue: isNegative ? -magnitude : magnitude,
			scale: scale
		)
	}

	/// 文字列を解析する。
	public init?(
		_ description: String,
	) {
		self.init(Substring(description))
	}

	private static func isDigit(
		_ byte: UInt8,
	) -> Bool {
		byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
	}

}


// MARK: 文字列への変換
extension BigDecimal {

	/// GDA の to-scientific-string（Java の `toString`）。
	///
	/// スケールが負、または調整済み指数（桁数 − 1 − スケール）が −6 未満なら
	/// 科学表記（`1.23E+3`、`1.23E-8`）。そうでなければ通常の表記（`0.00123`）。
	/// `BigDecimal(description)` で値とスケールが元に戻る。
	public var description: String {
		let coefficient: String = unscaledValue.magnitude.description
		let sign: String = unscaledValue < 0 ? "-" : ""

		// 通常の表記：スケール >= 0 かつ 調整済み指数 >= -6
		if scale >= 0 && scale <= coefficient.count + 5 {
			return sign + Self.plainDigits(coefficient, scale: scale)
		}

		let adjusted: BigInt = BigInt(coefficient.count - 1) - BigInt(scale)
		var result: String = sign + String(coefficient.prefix(1))

		if coefficient.count > 1 {
			result += "." + String(coefficient.dropFirst())
		}

		result += "E" + (adjusted < 0 ? "" : "+") + adjusted.description
		return result
	}

	/// 指数を使わない表記（Java の `toPlainString`）。
	/// スケールが負なら末尾に 0 を書く（元のスケールには戻らない）。
	public var plainString: String {
		if scale >= 0 {
			let sign: String = unscaledValue < 0 ? "-" : ""
			return sign + Self.plainDigits(unscaledValue.magnitude.description, scale: scale)
		}

		if isZero {
			return "0"
		}

		return unscaledValue.description + String(repeating: "0", count: -scale)
	}

	/// 係数の数字列に、スケール（0 以上）の位置で小数点を入れる。
	private static func plainDigits(
		_ coefficient: String,
		scale: Int,
	) -> String {
		if scale == 0 {
			return coefficient
		}

		let integerDigitCount: Int = coefficient.count - scale

		if integerDigitCount > 0 {
			return String(coefficient.prefix(integerDigitCount)) + "."
				+ String(coefficient.dropFirst(integerDigitCount))
		}

		return "0." + String(repeating: "0", count: -integerDigitCount) + coefficient
	}

}
