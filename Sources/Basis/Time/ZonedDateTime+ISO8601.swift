extension ZonedDateTime {

	/// ISO 8601の暦日・時刻・UTCオフセットから生成する。
	///
	/// 基本形式と拡張形式の秒までの日時を受け付ける。
	/// 小数秒は「.」「,」に続く1〜9桁、時差はZ、±hh、±hhmm、±hh:mm。
	/// 拡張形式では、符号付き6〜9桁の拡張年も受け付ける。
	/// 24:00:00は翌日の午前0時に変換する。うるう秒は扱わない。
	/// 不正な値、時差のない日時、±18時間を超える時差はnilを返す。
	/// 地域名や夏時間規則は復元せず、固定オフセットのゾーンを保持する。
	public static func iso8601(
		_ string: String,
	) -> Self? {
		var parser: ISO8601DateTimeParser
		= .init(string)

		guard
			let value = parser.parse()
		else { return nil }

		return value
	}

	/// ISO 8601の拡張形式で出力する（例: 2026-11-13T12:34:56+09:00）。
	///
	/// 小数秒はナノ秒精度で末尾の0を省略し、UTCはZとする。
	/// 年が0000〜9999の範囲外なら符号付きの拡張年を使う。
	/// 地域名は含めず、その日時に有効な時差を使う。
	/// 秒単位の時差はISO 8601で表せないため、同じ瞬間のUTC表現を返す。
	public var asISO8601String: String {
		let clock: ClockTime = asClockTime
		let offset: ZoneOffset = zone.offset(at: clock)
		let useUTC: Bool = offset.totalSeconds % 60 != 0
		let local: LocalDateTime
		= .dateTime(clock, zone: useUTC ? .utc : zone)
		let date: LocalDate = local.date
		let time: LocalTime = local.time
		let year: String

		if (0...9999).contains(date.year) {
			year = Self.iso8601Digits(date.year, width: 4)
		}
		else {
			year = (date.year < 0 ? "-" : "+")
				+ Self.iso8601Digits(abs(date.year), width: 6)
		}

		var result: String = year
			+ "-" + Self.iso8601Digits(date.month)
			+ "-" + Self.iso8601Digits(date.day)
			+ "T" + Self.iso8601Digits(time.hour)
			+ ":" + Self.iso8601Digits(time.minute)
			+ ":" + Self.iso8601Digits(time.second)

		if time.nano != 0 {
			var fraction: String = Self.iso8601Digits(time.nano, width: 9)

			while fraction.last == "0" {
				fraction.removeLast()
			}

			result += "." + fraction
		}

		return result + (useUTC ? "Z" : offset.description)
	}

	private static func iso8601Digits(
		_ value: Int,
		width: Int = 2,
	) -> String {
		let digits: String = String(value)
		return String(repeating: "0", count: max(0, width - digits.count))
			+ digits
	}

}


/// ASCIIの数字と区切りを読み、暦の妥当性を検証してから日時を作る。
private struct ISO8601DateTimeParser {

	let bytes: [UInt8]
	var position: Int = 0

	init(
		_ string: String,
	) {
		self.bytes = Array(string.utf8)
	}

	mutating func parse(
	) -> ZonedDateTime? {
		let negativeYear: Bool = consume(45)
		let expandedYear: Bool = negativeYear || consume(43)
		let year: Int
		let extended: Bool

		if expandedYear {
			let start: Int = position

			while let byte = current, (48...57).contains(byte) {
				position += 1
			}

			let count: Int = position - start
			position = start

			guard
				(6...9).contains(count),
				let magnitude = number(count),
				consume(45)
			else { return nil }

			year = negativeYear ? -magnitude : magnitude
			extended = true
		}
		else {
			guard let value = number(4) else { return nil }
			year = value
			extended = consume(45)
		}

		guard
			let month = number(2),
			!extended || consume(45),
			let day = number(2),
			consume(84),
			let hour = number(2),
			!extended || consume(58),
			let minute = number(2),
			!extended || consume(58),
			let second = number(2)
		else { return nil }

		var nano: Int = 0

		if consume(46) || consume(44) {
			var digits: Int = 0

			while let byte = current, (48...57).contains(byte) {
				guard digits < 9 else { return nil }
				nano = nano * 10 + Int(byte - 48)
				digits += 1
				position += 1
			}

			guard digits > 0 else { return nil }

			for _ in digits..<9 {
				nano *= 10
			}
		}

		guard
			let offset = parseOffset(),
			position == bytes.count,
			(1...12).contains(month),
			(0...24).contains(hour),
			(0...59).contains(minute),
			(0...59).contains(second)
		else { return nil }

		let date: LocalDate = .date(year, month, day)

		guard
			date.isValidCalendarDate,
			hour != 24 || (minute == 0 && second == 0 && nano == 0),
			year < Year.MAX_VALUE || month != 12 || day != 31 || hour != 24
		else { return nil }

		let normalizedDate: LocalDate
		= hour == 24 ? .date(epochDay: date.epochDay + 1) : date
		let zone: TimeZone
		= offset.totalSeconds == 0
			? .utc
			: .init(name: offset.description, offset: offset)

		return .init(
			dateTime: .dateTime(
				normalizedDate,
				.time(hour % 24, minute, second, nano: nano),
			),
			zone: zone,
		)
	}

	private mutating func parseOffset(
	) -> ZoneOffset? {
		if consume(90) {
			return .UTC
		}

		let negative: Bool = consume(45)

		guard negative || consume(43), let hour = number(2)
		else { return nil }

		var minute: Int = 0

		if position < bytes.count {
			_ = consume(58)

			guard let value = number(2) else { return nil }
			minute = value
		}

		guard
			hour <= 18,
			minute < 60,
			hour != 18 || minute == 0
		else { return nil }

		let seconds: Int = (hour * 3600 + minute * 60)
			* (negative ? -1 : 1)
		return .ofTotalSeconds(seconds)
	}

	private var current: UInt8? {
		position < bytes.count ? bytes[position] : nil
	}

	private mutating func consume(
		_ byte: UInt8,
	) -> Bool {
		guard current == byte else { return false }
		position += 1
		return true
	}

	private mutating func number(
		_ count: Int,
	) -> Int? {
		var value: Int = 0

		for _ in 0..<count {
			guard let byte = current, (48...57).contains(byte)
			else { return nil }

			value = value * 10 + Int(byte - 48)
			position += 1
		}

		return value
	}

}
