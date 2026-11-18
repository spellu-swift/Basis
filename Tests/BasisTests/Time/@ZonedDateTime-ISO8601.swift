@testable import Basis


@Suite struct ZonedDateTimeISO8601Tests {

	@Suite struct Units {

		@Test(arguments: [
			"2024-02-29T12:34:56.123456789+05:45",
			"20240229T123456.123456789+0545",
			"2024-02-29T12:34:56,123456789+05:45",
		])
		func 基本形式と拡張形式を読み込む(
			_ string: String,
		) throws {
			let value: ZonedDateTime
			= try #require(.iso8601(string))

			#expect(value.date == .date(2024, 2, 29))
			#expect(value.time == .time(12, 34, 56, nano: 123_456_789))
			#expect(value.zone.offset.totalSeconds == 20_700)
		}

		@Test(arguments: ["Z", "+00", "+0000", "+00:00"])
		func UTCを読み込む(
			_ suffix: String,
		) throws {
			let value: ZonedDateTime = try #require(
				.iso8601("1970-01-01T00:00:00" + suffix),
			)

			#expect(value == .EPOCH)
			#expect(value.asISO8601String == "1970-01-01T00:00:00Z")
		}

		@Test(arguments: [
			("+09", 32_400),
			("-03", -10_800),
			("-0330", -12_600),
			("-03:30", -12_600),
			("+18:00", 64_800),
			("-1800", -64_800),
		])
		func 時差を読み込む(
			_ suffix: String,
			_ seconds: Int,
		) throws {
			let value: ZonedDateTime = try #require(
				.iso8601("1970-01-01T00:00:00" + suffix),
			)

			#expect(value.zone.offset.totalSeconds == seconds)
			#expect(value.epochSecond == -seconds)
		}

		@Test(arguments: [
			("", 0),
			(".1", 100_000_000),
			(".01", 10_000_000),
			(".001", 1_000_000),
			(".0001", 100_000),
			(".00001", 10_000),
			(".000001", 1_000),
			(".0000001", 100),
			(".00000001", 10),
			(".000000001", 1),
			(".999999999", 999_999_999),
		])
		func 小数秒をナノ秒精度で読み書きする(
			_ fraction: String,
			_ nano: Int,
		) throws {
			let string: String = "2026-11-13T12:34:56" + fraction + "Z"
			let value: ZonedDateTime = try #require(.iso8601(string))

			#expect(value.time.nano == nano)
			#expect(value.asISO8601String == string)
		}

		@Test func 小数秒の末尾のゼロを省く() throws {
			let value: ZonedDateTime = try #require(
				.iso8601("2026-11-13T12:34:56.120000000Z"),
			)
			let zero: ZonedDateTime = try #require(
				.iso8601("2026-11-13T12:34:56.000Z"),
			)

			#expect(value.asISO8601String == "2026-11-13T12:34:56.12Z")
			#expect(zero.asISO8601String == "2026-11-13T12:34:56Z")
		}

		@Test(arguments: [
			("0000", 0),
			("0001", 1),
			("9999", 9999),
			("+010000", 10_000),
			("-000001", -1),
			("+999999999", Year.MAX_VALUE),
			("-999999999", Year.MIN_VALUE),
		])
		func 年の境界を読み書きする(
			_ yearString: String,
			_ year: Int,
		) throws {
			let string: String = yearString + "-01-01T00:00:00Z"
			let value: ZonedDateTime = try #require(.iso8601(string))

			#expect(value.date.year == year)
			#expect(value.asISO8601String == string)
		}

		@Test(arguments: [
			"", "2026-11-13", "2026-11-13T12:34:56",
			"2026-11-13T12:34Z", "2026-11-13 12:34:56Z",
			"2026-1-13T12:34:56Z", "2026-11-3T12:34:56Z",
			"2026-11-13T2:34:56Z", "2026-11-13T12:4:56Z",
			"2026-11-13T12:34:6Z", "2026-11-13T12:34:56.Z",
			"2026-11-13T12:34:56,Z", "2026-11-13T12:34:56.1234567890Z",
			"2026-00-13T12:34:56Z", "2026-13-13T12:34:56Z",
			"2026-11-00T12:34:56Z", "2026-11-31T12:34:56Z",
			"2026-02-29T12:34:56Z", "1900-02-29T12:34:56Z",
			"2026-11-13T25:00:00Z", "2026-11-13T24:01:00Z",
			"2026-11-13T24:00:01Z", "2026-11-13T24:00:00.000000001Z",
			"2026-11-13T12:60:00Z", "2026-11-13T12:34:60Z",
			"2026-11-13T12:34:56+19:00", "2026-11-13T12:34:56-18:01",
			"2026-11-13T12:34:56+09:60", "2026-11-13T12:34:56+09:",
			"2026-11-13T12:34:56+9", "2026-11-13T12:34:56+09:00:01",
			"2026-11-13T12:34:56Zsuffix", " 2026-11-13T12:34:56Z",
			"2026-11-13T12:34:56Z\n", "2026-11-13T12:34:56ZZ",
			"２０２６-11-13T12:34:56Z", "2026-11-13T12:34:56.１２Z",
			"20261113T12:34:56Z", "2026-11-13T123456Z",
			"2026-W46-5T12:34:56Z", "2026-317T12:34:56Z",
			"+1000000000-01-01T00:00:00Z", "-1000000000-01-01T00:00:00Z",
			"+999999999-12-31T24:00:00Z", "+10000-01-01T00:00:00Z",
			"99999999999999999999999999999999999999999",
		])
		func 不正または未対応の入力はnilになる(
			_ string: String,
		) {
			#expect(ZonedDateTime.iso8601(string) == nil)
		}

	}

	@Suite struct Semantics {

		@Test(arguments: [
			("2024-02-28T24:00:00Z", "2024-02-29T00:00:00Z"),
			("2024-02-29T24:00:00Z", "2024-03-01T00:00:00Z"),
			("20261231T240000+09", "2027-01-01T00:00:00+09:00"),
		])
		func 一日の終わりは翌日の午前零時になる(
			_ input: String,
			_ expected: String,
		) throws {
			let value: ZonedDateTime = try #require(.iso8601(input))

			#expect(value.asISO8601String == expected)
		}

		@Test(arguments: [
			("2026-01-15T12:34:56-05:00", 1),
			("2026-07-15T12:34:56-04:00", 7),
		])
		func 夏時間を含む地域の日時を固定時差で往復する(
			_ expected: String,
			_ month: Int,
		) throws {
			let zone: TimeZone = try .named("America/New_York")
			let original: ZonedDateTime
			= .dateTime(2026, month, 15, 12, 34, 56, zone: zone)
			let string: String = original.asISO8601String
			let parsed: ZonedDateTime = try #require(.iso8601(string))

			#expect(string == expected)
			#expect(parsed.dateTime == original.dateTime)
			#expect(parsed.asClockTime == original.asClockTime)
			#expect(parsed.zone.offset == zone.offset(at: original.asClockTime))
		}

		@Test(arguments: [1, -1, 20_730, -20_730])
		func 秒単位の時差は同じ瞬間のUTC表現になる(
			_ seconds: Int,
		) throws {
			let zone: TimeZone
			= .init(name: "Fixed", offset: .ofTotalSeconds(seconds))
			let original: ZonedDateTime
			= .dateTime(2026, 1, 1, 0, 0, 0, nano: 1, zone: zone)
			let string: String = original.asISO8601String
			let parsed: ZonedDateTime = try #require(.iso8601(string))

			#expect(string.hasSuffix("Z"))
			#expect(parsed.asClockTime == original.asClockTime)
			#expect(parsed.time.nano == 1)
		}

		@Test func ナノ秒と日付をまたぐ時差を保持する() throws {
			let value: ZonedDateTime = try #require(
				.iso8601("1970-01-01T00:00:00.123456789+09:00"),
			)
			let parsed: ZonedDateTime = try #require(
				.iso8601(value.asISO8601String),
			)

			#expect(value.asClockTime == .clock(-32_400, 123_456_789))
			#expect(parsed == value)
			#expect(value.asISO8601String
				== "1970-01-01T00:00:00.123456789+09:00")
		}

	}

}
