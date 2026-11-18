@testable import Basis


/// POSIXで実装したタイムゾーンを、期待値と比べる。
///
/// 期待値は、tzdata 2026f を `zdump -v` で読んで作った。
/// 各ゾーンで、1970年の時差と、最初・2001年に近い・最後の切り替わりの前後を選んだ。
/// 将来の規則はtzdataの更新で変わりうるので、2026-11-01より前の時刻だけを使う。
@Suite struct TimeZonePOSIXTests {

	struct Expectation : Sendable, CustomTestStringConvertible {
		let name: String
		/// 2001-01-01T00:00:00Z時点の時差
		let baseOffset: Int
		/// (エポック秒, 時差)
		let offsets: [(second: Int, offset: Int)]

		var testDescription: String { name }
	}

	static let expectations: [Expectation] = [
		.init(
			name: "UTC",
			baseOffset: 0,
			offsets: [
				(0, 0),	// 1970-01-01T00:00:00Z
				(1789978477, 0),	// 2026-09-21T08:14:37Z
			],
		),
		.init(
			name: "Asia/Tokyo",
			baseOffset: 32400,
			offsets: [
				(0, 32400),	// 1970-01-01T00:00:00Z
				(1789978477, 32400),	// 2026-09-21T08:14:37Z
			],
		),
		.init(
			name: "Asia/Kolkata",
			baseOffset: 19800,
			offsets: [
				(0, 19800),	// 1970-01-01T00:00:00Z
				(1789978477, 19800),	// 2026-09-21T08:14:37Z
			],
		),
		.init(
			name: "Asia/Kathmandu",
			baseOffset: 20700,
			offsets: [
				(0, 19800),	// 1970-01-01T00:00:00Z
				(504901799, 19800),	// 1985-12-31T18:29:59Z
				(504901800, 20700),	// 1985-12-31T18:30:00Z
			],
		),
		.init(
			name: "America/New_York",
			baseOffset: -18000,
			offsets: [
				(0, -18000),	// 1970-01-01T00:00:00Z
				(9961199, -18000),	// 1970-04-26T06:59:59Z
				(9961200, -14400),	// 1970-04-26T07:00:00Z
				(972799199, -14400),	// 2000-10-29T05:59:59Z
				(972799200, -18000),	// 2000-10-29T06:00:00Z
				(1772953199, -18000),	// 2026-03-08T06:59:59Z
				(1772953200, -14400),	// 2026-03-08T07:00:00Z
			],
		),
		.init(
			name: "America/Los_Angeles",
			baseOffset: -28800,
			offsets: [
				(0, -28800),	// 1970-01-01T00:00:00Z
				(9971999, -28800),	// 1970-04-26T09:59:59Z
				(9972000, -25200),	// 1970-04-26T10:00:00Z
				(972809999, -25200),	// 2000-10-29T08:59:59Z
				(972810000, -28800),	// 2000-10-29T09:00:00Z
				(1772963999, -28800),	// 2026-03-08T09:59:59Z
				(1772964000, -25200),	// 2026-03-08T10:00:00Z
			],
		),
		.init(
			name: "America/Sao_Paulo",
			baseOffset: -7200,
			offsets: [
				(0, -10800),	// 1970-01-01T00:00:00Z
				(499748399, -10800),	// 1985-11-02T02:59:59Z
				(499748400, -7200),	// 1985-11-02T03:00:00Z
				(982461599, -7200),	// 2001-02-18T01:59:59Z
				(982461600, -10800),	// 2001-02-18T02:00:00Z
				(1550368799, -7200),	// 2019-02-17T01:59:59Z
				(1550368800, -10800),	// 2019-02-17T02:00:00Z
			],
		),
		.init(
			name: "America/St_Johns",
			baseOffset: -12600,
			offsets: [
				(0, -12600),	// 1970-01-01T00:00:00Z
				(9955799, -12600),	// 1970-04-26T05:29:59Z
				(9955800, -9000),	// 1970-04-26T05:30:00Z
				(972786659, -9000),	// 2000-10-29T02:30:59Z
				(972786660, -12600),	// 2000-10-29T02:31:00Z
				(1772947799, -12600),	// 2026-03-08T05:29:59Z
				(1772947800, -9000),	// 2026-03-08T05:30:00Z
			],
		),
		.init(
			name: "Europe/London",
			baseOffset: 0,
			offsets: [
				(0, 3600),	// 1970-01-01T00:00:00Z
				(57722399, 3600),	// 1971-10-31T01:59:59Z
				(57722400, 0),	// 1971-10-31T02:00:00Z
				(972781199, 3600),	// 2000-10-29T00:59:59Z
				(972781200, 0),	// 2000-10-29T01:00:00Z
				(1792889999, 3600),	// 2026-10-25T00:59:59Z
				(1792890000, 0),	// 2026-10-25T01:00:00Z
			],
		),
		.init(
			name: "Europe/Berlin",
			baseOffset: 3600,
			offsets: [
				(0, 3600),	// 1970-01-01T00:00:00Z
				(323830799, 3600),	// 1980-04-06T00:59:59Z
				(323830800, 7200),	// 1980-04-06T01:00:00Z
				(972781199, 7200),	// 2000-10-29T00:59:59Z
				(972781200, 3600),	// 2000-10-29T01:00:00Z
				(1792889999, 7200),	// 2026-10-25T00:59:59Z
				(1792890000, 3600),	// 2026-10-25T01:00:00Z
			],
		),
		.init(
			name: "Europe/Moscow",
			baseOffset: 10800,
			offsets: [
				(0, 10800),	// 1970-01-01T00:00:00Z
				(354920399, 10800),	// 1981-03-31T20:59:59Z
				(354920400, 14400),	// 1981-03-31T21:00:00Z
				(972773999, 14400),	// 2000-10-28T22:59:59Z
				(972774000, 10800),	// 2000-10-28T23:00:00Z
				(1414274399, 14400),	// 2014-10-25T21:59:59Z
				(1414274400, 10800),	// 2014-10-25T22:00:00Z
			],
		),
		.init(
			name: "Australia/Sydney",
			baseOffset: 39600,
			offsets: [
				(0, 36000),	// 1970-01-01T00:00:00Z
				(57686399, 36000),	// 1971-10-30T15:59:59Z
				(57686400, 39600),	// 1971-10-30T16:00:00Z
				(985449599, 39600),	// 2001-03-24T15:59:59Z
				(985449600, 36000),	// 2001-03-24T16:00:00Z
				(1791043199, 36000),	// 2026-10-03T15:59:59Z
				(1791043200, 39600),	// 2026-10-03T16:00:00Z
			],
		),
		.init(
			name: "Australia/Lord_Howe",
			baseOffset: 39600,
			offsets: [
				(0, 36000),	// 1970-01-01T00:00:00Z
				(352216799, 36000),	// 1981-02-28T13:59:59Z
				(352216800, 37800),	// 1981-02-28T14:00:00Z
				(985445999, 39600),	// 2001-03-24T14:59:59Z
				(985446000, 37800),	// 2001-03-24T15:00:00Z
				(1791041399, 37800),	// 2026-10-03T15:29:59Z
				(1791041400, 39600),	// 2026-10-03T15:30:00Z
			],
		),
		.init(
			name: "Pacific/Auckland",
			baseOffset: 46800,
			offsets: [
				(0, 43200),	// 1970-01-01T00:00:00Z
				(152632799, 43200),	// 1974-11-02T13:59:59Z
				(152632800, 46800),	// 1974-11-02T14:00:00Z
				(984837599, 46800),	// 2001-03-17T13:59:59Z
				(984837600, 43200),	// 2001-03-17T14:00:00Z
				(1790431199, 43200),	// 2026-09-26T13:59:59Z
				(1790431200, 46800),	// 2026-09-26T14:00:00Z
			],
		),
		.init(
			name: "Pacific/Apia",
			baseOffset: -39600,
			offsets: [
				(0, -39600),	// 1970-01-01T00:00:00Z
				(1285498799, -39600),	// 2010-09-26T10:59:59Z
				(1285498800, -36000),	// 2010-09-26T11:00:00Z
				(1325239199, -36000),	// 2011-12-30T09:59:59Z
				(1325239200, 50400),	// 2011-12-30T10:00:00Z
				(1617458399, 50400),	// 2021-04-03T13:59:59Z
				(1617458400, 46800),	// 2021-04-03T14:00:00Z
			],
		),
		.init(
			name: "Pacific/Chatham",
			baseOffset: 49500,
			offsets: [
				(0, 45900),	// 1970-01-01T00:00:00Z
				(152632799, 45900),	// 1974-11-02T13:59:59Z
				(152632800, 49500),	// 1974-11-02T14:00:00Z
				(984837599, 49500),	// 2001-03-17T13:59:59Z
				(984837600, 45900),	// 2001-03-17T14:00:00Z
				(1790431199, 45900),	// 2026-09-26T13:59:59Z
				(1790431200, 49500),	// 2026-09-26T14:00:00Z
			],
		),
		.init(
			name: "Africa/Casablanca",
			baseOffset: 0,
			offsets: [
				(0, 0),	// 1970-01-01T00:00:00Z
				(141263999, 0),	// 1974-06-23T23:59:59Z
				(141264000, 3600),	// 1974-06-24T00:00:00Z
				(1212278399, 0),	// 2008-05-31T23:59:59Z
				(1212278400, 3600),	// 2008-06-01T00:00:00Z
				(1789865999, 3600),	// 2026-09-20T00:59:59Z
				(1789866000, 0),	// 2026-09-20T01:00:00Z
			],
		),
		.init(
			name: "Antarctica/Troll",
			baseOffset: 0,
			offsets: [
				(0, 0),	// 1970-01-01T00:00:00Z
				(1792889999, 7200),	// 2026-10-25T00:59:59Z
				(1792890000, 0),	// 2026-10-25T01:00:00Z
			],
		),
	]


	@Test(arguments: expectations)
	func 時差が期待値と一致する(
		_ expectation: Expectation,
	) throws {
		let zone: TimeZone = try .named(expectation.name)

		for (second, offset) in expectation.offsets {
			#expect(
				zone.offset(at: .clock(second)).totalSeconds == offset,
				"\(expectation.name) \(second)",
			)
		}
	}


	@Test(arguments: expectations)
	func 基準オフセットが期待値と一致する(
		_ expectation: Expectation,
	) throws {
		let zone: TimeZone = try .named(expectation.name)

		#expect(zone.offset.totalSeconds == expectation.baseOffset)
	}


	@Test func 存在しない名前はエラーになる() {
		#expect(throws: GeneralError.self) { try TimeZone.named("Nowhere/Nothing") }
		#expect(throws: GeneralError.self) { try TimeZone.named("../etc/passwd") }
		#expect(throws: GeneralError.self) { try TimeZone.named("/etc/localtime") }
		#expect(throws: GeneralError.self) { try TimeZone.named("") }
	}

}


@Suite struct PosixRuleTests {

	@Test func 夏時間のない規則() throws {
		let rule: PosixRule = try #require(PosixRule(string: "JST-9"))

		#expect(rule.offset(at: 0) == 9 * 3600)
		#expect(rule.daylight == nil)
	}


	@Test func 分を含む規則と山括弧の名前() throws {
		let rule: PosixRule = try #require(PosixRule(string: "<+0545>-5:45"))

		#expect(rule.offset(at: 0) == 5 * 3600 + 45 * 60)
	}


	@Test func 北半球の夏時間() throws {
		let rule: PosixRule = try #require(PosixRule(string: "EST5EDT,M3.2.0,M11.1.0"))

		// 2030-03-10 は第2日曜日。02:00 EST (07:00Z) から夏時間。
		let start: Int64 = 1_899_356_400

		#expect(rule.offset(at: start - 1) == -5 * 3600)
		#expect(rule.offset(at: start) == -4 * 3600)

		// 2030-11-03 は第1日曜日。02:00 EDT (06:00Z) で終わる。
		let end: Int64 = 1_919_916_000

		#expect(rule.offset(at: end - 1) == -4 * 3600)
		#expect(rule.offset(at: end) == -5 * 3600)
	}


	@Test func 南半球の夏時間() throws {
		let rule: PosixRule = try #require(PosixRule(string: "AEST-10AEDT,M10.1.0,M4.1.0/3"))

		// 2030-01-01T00:00Z は夏時間、2030-07-01T00:00Z は標準時
		#expect(rule.offset(at: 1_893_456_000) == 11 * 3600)
		#expect(rule.offset(at: 1_909_094_400) == 10 * 3600)
	}


	@Test func 不正な規則は受け付けない() {
		#expect(PosixRule(string: "") == nil)
		#expect(PosixRule(string: "AB-1") == nil)
		#expect(PosixRule(string: "EST5EDT,M13.1.0,M11.1.0") == nil)
		#expect(PosixRule(string: "EST5EDT,M3.2.0") == nil)
	}


	@Test func 最後の切り替わりより後は末尾の規則を使う() throws {
		let zone: TimeZone = try .named("America/New_York")

		// 2100-07-01T12:00Z は夏時間、2100-01-01T12:00Z は標準時
		#expect(zone.offset(at: .clock(4_118_126_400)).totalSeconds == -4 * 3600)
		#expect(zone.offset(at: .clock(4_102_488_000)).totalSeconds == -5 * 3600)
	}

}
