

///
/// タイムゾーンの規則
///
/// TZif形式（RFC 8536）のファイルと、POSIXのTZ文字列から作る。
/// 指定した瞬間のUTCオフセット（秒）を求める。
///
struct TimeZoneRules : Sendable {

	/// 切り替わりの時刻（エポック秒、昇順）
	let transitions: [Int64]

	/// 各切り替わり以降のUTCオフセット（秒）
	let offsets: [Int]

	/// 最初の切り替わりより前のUTCオフセット（秒）
	let initialOffset: Int

	/// 最後の切り替わりより後の規則
	let footer: PosixRule?

	/// 指定した瞬間のUTCオフセット（秒）
	func offset(
		at epochSecond: Int64,
	) -> Int {
		if
			let footer,
			transitions.isEmpty
				|| epochSecond >= transitions[transitions.count - 1]
		{
			return footer.offset(at: epochSecond)
		}

		guard
			let first = transitions.first,
			epochSecond >= first
		else { return initialOffset }

		// epochSecond以下で最後の切り替わりを二分探索する。
		var low: Int = 0
		var high: Int = transitions.count - 1

		while low < high {
			let middle: Int = (low + high + 1) / 2

			if transitions[middle] <= epochSecond {
				low = middle
			}
			else {
				high = middle - 1
			}
		}

		return offsets[low]
	}

}


// MARK: TZif


extension TimeZoneRules {

	/// TZif形式のデータを解析する。不正な形式ならnil。
	init?(
		tzif bytes: [UInt8],
	) {
		var reader: TZifReader
		= .init(bytes: bytes)

		guard
			let header = reader.header()
		else { return nil }

		// バージョン2以降は、64ビットの時刻を持つ2つ目のデータを使う。
		var data: (transitions: [Int64], indices: [Int], types: [Int])

		if header.version >= 2 {
			guard
				reader.skip(header.dataLength(timeSize: 4)),
				let header64 = reader.header(),
				let data64 = reader.data(header64, timeSize: 8)
			else { return nil }

			data = data64
			reader.skip(
				header64.dataLength(timeSize: 8)
					- header64.ruleLength(timeSize: 8)
			)
		}
		else {
			guard
				let data32 = reader.data(header, timeSize: 4)
			else { return nil }

			data = data32
		}

		guard
			data.types.isNotEmpty,
			data.indices.allSatisfy({ data.types.indices.contains($0) })
		else { return nil }

		transitions = data.transitions
		offsets = data.indices.map { data.types[$0] }
		// RFC 8536: 最初の切り替わりより前は、ローカル時刻の種類0を使う。
		initialOffset = data.types[0]
		footer = header.version >= 2
			? reader.footer().flatMap { PosixRule(string: $0) }
			: nil
	}

}


/// TZif形式のデータを先頭から読む。
private struct TZifReader {

	let bytes: [UInt8]
	var position: Int = 0

	struct Header {
		let version: Int
		let isutcnt: Int
		let isstdcnt: Int
		let leapcnt: Int
		let timecnt: Int
		let typecnt: Int
		let charcnt: Int

		/// ヘッダーの後に続くデータの長さ
		func dataLength(
			timeSize: Int,
		) -> Int {
			ruleLength(timeSize: timeSize)
				+ charcnt
				+ leapcnt * (timeSize + 4)
				+ isstdcnt
				+ isutcnt
		}

		/// 切り替わりの時刻・種類の番号・種類の定義の長さ
		func ruleLength(
			timeSize: Int,
		) -> Int {
			timecnt * timeSize + timecnt + typecnt * 6
		}
	}

	init(
		bytes: [UInt8],
	) {
		self.bytes = bytes
	}

	@discardableResult
	mutating func skip(
		_ count: Int,
	) -> Bool {
		guard
			count >= 0,
			position + count <= bytes.count
		else { return false }

		position += count
		return true
	}

	mutating func integer(
		size: Int,
	) -> Int64? {
		guard
			position + size <= bytes.count
		else { return nil }

		var value: UInt64 = 0

		for byte in bytes[position ..< position + size] {
			value = value << 8 | UInt64(byte)
		}

		position += size

		// 符号付きの整数として解釈する。
		let shift: UInt64 = UInt64(64 - size * 8)
		return Int64(bitPattern: value << shift) >> Int64(shift)
	}

	mutating func header(
	) -> Header? {
		guard
			position + 44 <= bytes.count,
			Array(bytes[position ..< position + 4]) == Array("TZif".utf8)
		else { return nil }

		let versionByte: UInt8 = bytes[position + 4]
		let version: Int
		= versionByte == 0
			? 1
			: Int(versionByte) - Int(UInt8(ascii: "0"))

		position += 20

		var counts: [Int] = []

		for _ in 0 ..< 6 {
			guard
				let count = integer(size: 4),
				count >= 0
			else { return nil }

			counts.append(Int(count))
		}

		return Header(
			version: version,
			isutcnt: counts[0],
			isstdcnt: counts[1],
			leapcnt: counts[2],
			timecnt: counts[3],
			typecnt: counts[4],
			charcnt: counts[5],
		)
	}

	/// 切り替わりの時刻・種類の番号・各種類のUTCオフセットを読む。
	mutating func data(
		_ header: Header,
		timeSize: Int,
	) -> (transitions: [Int64], indices: [Int], types: [Int])? {
		var transitions: [Int64] = []
		var indices: [Int] = []
		var types: [Int] = []

		for _ in 0 ..< header.timecnt {
			guard
				let time = integer(size: timeSize)
			else { return nil }

			transitions.append(time)
		}

		for _ in 0 ..< header.timecnt {
			guard
				let index = integer(size: 1)
			else { return nil }

			indices.append(Int(UInt8(truncatingIfNeeded: index)))
		}

		for _ in 0 ..< header.typecnt {
			guard
				let offset = integer(size: 4),
				skip(2)
			else { return nil }

			types.append(Int(offset))
		}

		return (transitions, indices, types)
	}

	/// 末尾の改行で囲まれたTZ文字列を読む。
	mutating func footer(
	) -> String? {
		guard
			position < bytes.count,
			bytes[position] == UInt8(ascii: "\n")
		else { return nil }

		let start: Int = position + 1

		guard
			let end = bytes[start...].firstIndex(of: UInt8(ascii: "\n")),
			end > start
		else { return nil }

		return String(decoding: bytes[start ..< end], as: UTF8.self)
	}

}


// MARK: POSIXのTZ文字列


///
/// POSIXのTZ文字列で表した規則（例: `EST5EDT,M3.2.0,M11.1.0`）
///
/// RFC 8536の拡張（時刻に負の値や24時間を超える値を許す）にも対応する。
///
struct PosixRule : Sendable {

	/// 標準時のUTCオフセット（秒）
	let standardOffset: Int

	/// 夏時間の規則。夏時間がなければnil。
	let daylight: Daylight?

	struct Daylight : Sendable {

		/// 夏時間のUTCオフセット（秒）
		let offset: Int

		/// 夏時間の開始。標準時のローカル時刻で表す。
		let start: Transition

		/// 夏時間の終了。夏時間のローカル時刻で表す。
		let end: Transition

	}

	struct Transition : Sendable {

		enum Date : Sendable {
			/// Jn: 1〜365日目。閏日は数えない。
			case julian(Int)
			/// n: 0〜365日目。閏日も数える。
			case zeroBased(Int)
			/// Mm.w.d: m月の第w週（5は最終週）のd曜日（0は日曜）
			case monthWeekDay(month: Int, week: Int, day: Int)
		}

		let date: Date

		/// その日の0時からの秒数
		let time: Int

	}

	/// 指定した瞬間のUTCオフセット（秒）
	func offset(
		at epochSecond: Int64,
	) -> Int {
		guard
			let daylight
		else { return standardOffset }

		let second: Int = Int(epochSecond)

		// 標準時のローカル時刻での年の、夏時間の開始と終了（UTC）
		let year: Int = CivilDate(
			epochDay: Self.floorDivide(
				second + standardOffset,
				SECONDS_PER_DAY,
			),
		).year

		let start: Int = daylight.start.localSecond(in: year) - standardOffset
		let end: Int = daylight.end.localSecond(in: year) - daylight.offset

		let isDaylight: Bool
		= start < end
			// 北半球: 開始から終了までが夏時間
			? (start <= second && second < end)
			// 南半球: 年の初めから終了までと、開始から年末までが夏時間
			: (second < end || start <= second)

		return isDaylight ? daylight.offset : standardOffset
	}

	static func floorDivide(
		_ value: Int,
		_ divisor: Int,
	) -> Int {
		let quotient: Int = value / divisor

		return (value % divisor < 0) ? quotient - 1 : quotient
	}

}


extension PosixRule.Transition {

	/// 指定した年の切り替わりのローカル時刻（エポック秒として表す）
	func localSecond(
		in year: Int,
	) -> Int {
		let epochDay: Int

		switch date {
			case .julian(let day):
				// 閏年でも2月29日を数えない。
				let leap: Int = (CivilDate.isLeap(year) && day >= 60) ? 1 : 0
				epochDay = Self.newYearDay(year) + day - 1 + leap

			case .zeroBased(let day):
				epochDay = Self.newYearDay(year) + day

			case .monthWeekDay(let month, let week, let weekday):
				let first: Int
				= CivilDate(year: year, month: month, day: 1).epochDay
				// 1970-01-01は木曜日（4）
				let firstWeekday: Int = ((first % 7) + 7 + 4) % 7
				var day: Int
				= first
					+ (weekday - firstWeekday + 7) % 7
					+ (week - 1) * 7
				let days: Int = CivilDate.days(inMonth: month, year: year)

				while day >= first + days {
					day -= 7
				}

				epochDay = day
		}

		return epochDay * SECONDS_PER_DAY + time
	}
	
	/// 指定した年の1月1日（1970-01-01からの日数）
	static func newYearDay(
		_ year: Int,
	) -> Int {
		CivilDate(year: year, month: 1, day: 1).epochDay
	}

}


extension PosixRule {

	/// TZ文字列を解析する。不正な形式ならnil。
	init?(
		string: String,
	) {
		var scanner: PosixRuleScanner
		= .init(string)

		guard
			scanner.name(),
			let standard = scanner.offset()
		else { return nil }

		// POSIXのオフセットはUTCからの差の符号が逆（西が正）
		standardOffset = -standard

		guard
			scanner.isNotAtEnd
		else {
			daylight = nil
			return
		}

		guard
			scanner.name()
		else { return nil }

		var daylightOffset: Int = standardOffset + 3600

		if
			scanner.peek != ",",
			scanner.isNotAtEnd
		{
			guard
				let offset = scanner.offset()
			else { return nil }

			daylightOffset = -offset
		}

		guard
			scanner.consume(","),
			let start = scanner.transition(),
			scanner.consume(","),
			let end = scanner.transition(),
			!scanner.isNotAtEnd
		else { return nil }

		daylight = .init(
			offset: daylightOffset,
			start: start,
			end: end,
		)
	}

}


/// TZ文字列を先頭から読む。
private struct PosixRuleScanner {

	let characters: [Character]
	var position: Int = 0

	init(
		_ string: String,
	) {
		characters = Array(string)
	}

	var isNotAtEnd: Bool {
		position < characters.count
	}

	var peek: Character? {
		isNotAtEnd ? characters[position] : nil
	}

	mutating func consume(
		_ character: Character,
	) -> Bool {
		guard
			peek == character
		else { return false }

		position += 1
		return true
	}

	/// 名前（英字3文字以上、または<>で囲んだもの）を読み飛ばす。
	mutating func name(
	) -> Bool {
		if consume("<") {
			guard
				let end = characters[position...].firstIndex(of: ">")
			else { return false }

			let length: Int = end - position
			position = end + 1
			return length >= 3
		}

		let start: Int = position

		while let character = peek, character.isLetter {
			position += 1
		}

		return position - start >= 3
	}

	mutating func number(
	) -> Int? {
		let start: Int = position
		var value: Int = 0

		while
			let character = peek,
			character.isASCII,
			let digit = character.wholeNumberValue
		{
			value = value * 10 + digit
			position += 1
		}

		return position > start ? value : nil
	}

	/// [+-]hh[:mm[:ss]] を秒に変換する。
	mutating func offset(
	) -> Int? {
		var sign: Int = 1

		if consume("-") {
			sign = -1
		}
		else {
			_ = consume("+")
		}

		guard
			let hours = number()
		else { return nil }

		var seconds: Int = hours * 3600

		if consume(":") {
			guard
				let minutes = number()
			else { return nil }

			seconds += minutes * 60

			if consume(":") {
				guard
					let secs = number()
				else { return nil }

				seconds += secs
			}
		}

		return sign * seconds
	}

	/// date[/time] を読む。
	mutating func transition(
	) -> PosixRule.Transition? {
		let date: PosixRule.Transition.Date

		if consume("J") {
			guard
				let day = number(),
				(1 ... 365).contains(day)
			else { return nil }

			date = .julian(day)
		}
		else if consume("M") {
			guard
				let month = number(),
				consume("."),
				let week = number(),
				consume("."),
				let day = number(),
				(1 ... 12).contains(month),
				(1 ... 5).contains(week),
				(0 ... 6).contains(day)
			else { return nil }

			date = .monthWeekDay(month: month, week: week, day: day)
		}
		else {
			guard
				let day = number(),
				(0 ... 365).contains(day)
			else { return nil }

			date = .zeroBased(day)
		}

		var time: Int = 2 * 3600

		if consume("/") {
			guard
				let value = offset()
			else { return nil }

			time = value
		}

		return .init(date: date, time: time)
	}

}


// MARK: 暦の計算


/// 先発グレゴリオ暦の日付。TZの規則の計算にだけ使う。
private struct CivilDate {

	let year: Int
	let month: Int
	let day: Int

	init(
		year: Int,
		month: Int,
		day: Int,
	) {
		self.year = year
		self.month = month
		self.day = day
	}

	/// 1970-01-01からの日数から作る。
	init(
		epochDay: Int,
	) {
		// Howard Hinnant の civil_from_days
		let z: Int = epochDay + 719_468
		let era: Int = (z >= 0 ? z : z - 146_096) / 146_097
		let doe: Int = z - era * 146_097
		let yoe: Int = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
		let doy: Int = doe - (365 * yoe + yoe / 4 - yoe / 100)
		let mp: Int = (5 * doy + 2) / 153

		day = doy - (153 * mp + 2) / 5 + 1
		month = mp < 10 ? mp + 3 : mp - 9
		year = yoe + era * 400 + (month <= 2 ? 1 : 0)
	}

	/// 1970-01-01からの日数
	var epochDay: Int {
		// Howard Hinnant の days_from_civil
		let y: Int = month <= 2 ? year - 1 : year
		let era: Int = (y >= 0 ? y : y - 399) / 400
		let yoe: Int = y - era * 400
		let mp: Int = month > 2 ? month - 3 : month + 9
		let doy: Int = (153 * mp + 2) / 5 + day - 1
		let doe: Int = yoe * 365 + yoe / 4 - yoe / 100 + doy

		return era * 146_097 + doe - 719_468
	}

	static func isLeap(
		_ year: Int,
	) -> Bool {
		year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
	}

	static func days(
		inMonth month: Int,
		year: Int,
	) -> Int {
		switch month {
			case 2: isLeap(year) ? 29 : 28
			case 4, 6, 9, 11: 30
			default: 31
		}
	}

}
