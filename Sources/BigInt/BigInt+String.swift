// MARK: 文字列からの生成
extension BigInt: LosslessStringConvertible {

	/// 文字列を解析する。
	///
	/// 先頭の `+` か `-` と、基数 `radix`（2〜36）の数字（大文字小文字どちらも）。
	/// 空文字、符号だけ、空白、`0x` などの接頭辞、`_` を含むと `nil`。
	/// `Int("…", radix:)` と同じ厳格さ。基数が範囲外なら実行時エラー。
	public init?<S: StringProtocol>(
		_ text: S,
		radix: Int = 10,
	) {
		precondition((2 ... 36).contains(radix), "Radix not in range 2...36")
		var bytes: Substring.UTF8View = Substring(text).utf8
		var isNegative: Bool = false

		if let first = bytes.first, first == UInt8(ascii: "+") || first == UInt8(ascii: "-") {
			isNegative = first == UInt8(ascii: "-")
			bytes = bytes.dropFirst()
		}

		if bytes.isEmpty {
			return nil
		}

		// 1 ワードに収まる桁数ずつまとめて取り込む
		let chunk: (power: UInt, digits: Int) = Self.chunk(radix: radix)
		var limbs: [UInt] = []
		var value: UInt = 0
		var digits: Int = 0
		var power: UInt = 1

		for byte in bytes {
			guard
				let digit = Self.digitValue(byte),
				digit < radix
			else { return nil }

			value = value * UInt(radix) + UInt(digit)
			power *= UInt(radix)
			digits += 1

			if digits == chunk.digits {
				Limbs.multiplyAdd(&limbs, chunk.power, value)
				value = 0
				digits = 0
				power = 1
			}
		}

		if digits > 0 {
			Limbs.multiplyAdd(&limbs, power, value)
		}

		self.init(_isNegative: isNegative, limbs: limbs)
	}

	/// 10 進数の文字列を解析する。
	public init?(
		_ description: String,
	) {
		self.init(description, radix: 10)
	}

	/// 数字の値。数字でなければ `nil`。
	private static func digitValue(
		_ byte: UInt8,
	) -> Int? {
		switch byte {
			case UInt8(ascii: "0") ... UInt8(ascii: "9"):
				return Int(byte - UInt8(ascii: "0"))
			case UInt8(ascii: "a") ... UInt8(ascii: "z"):
				return Int(byte - UInt8(ascii: "a")) + 10
			case UInt8(ascii: "A") ... UInt8(ascii: "Z"):
				return Int(byte - UInt8(ascii: "A")) + 10
			default:
				return nil
		}
	}

	/// 1 ワードに収まる、基数の冪の最大値とその桁数。
	internal static func chunk(
		radix: Int,
	) -> (power: UInt, digits: Int) {
		var power: UInt = UInt(radix)
		var digits: Int = 1

		while true {
			let (next, overflow) = power.multipliedReportingOverflow(
				by: UInt(radix)
			)

			if overflow {
				return (power, digits)
			}

			power = next
			digits += 1
		}
	}

}


// MARK: 文字列への変換
extension BigInt {

	/// 10 進数の文字列。
	public var description: String {
		string(radix: 10, uppercase: false)
	}

	/// 基数 `radix`（2〜36）の文字列。
	internal func string(
		radix: Int,
		uppercase: Bool,
	) -> String {
		precondition((2 ... 36).contains(radix), "Radix not in range 2...36")

		if isZero {
			return "0"
		}

		// 1 ワードに収まる桁数ずつ、下位から取り出す
		let chunk: (power: UInt, digits: Int) = Self.chunk(radix: radix)
		var chunks: [UInt] = []
		var rest: [UInt] = limbs

		while !rest.isEmpty {
			let (quotient, remainder) = Limbs.divide(rest, by: chunk.power)
			chunks.append(remainder)
			rest = quotient
		}

		var result: String = isNegative ? "-" : ""
		result += String(chunks[chunks.count - 1], radix: radix, uppercase: uppercase)

		for value in chunks.dropLast().reversed() {
			let text: String = String(value, radix: radix, uppercase: uppercase)
			result += String(repeating: "0", count: chunk.digits - text.count)
			result += text
		}

		return result
	}

}
extension String {

	/// `BigInt` を基数 `radix`（2〜36）の文字列にする。
	public init(
		_ value: BigInt,
		radix: Int = 10,
		uppercase: Bool = false,
	) {
		self = value.string(radix: radix, uppercase: uppercase)
	}

}
