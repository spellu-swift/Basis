@testable import Basis


@Suite struct POSIXTimeTests {

	@Test(arguments: [
		("1970-01-01T00:00:00Z", 0),
		("2001-01-01T00:00:00Z", 978_307_200),
		("2030-03-10T07:00:00Z", 1_899_356_400),
		("1969-12-31T23:59:59Z", -1),
	])
	func strptimeは書式に従いUTCの時刻にする(
		string: String,
		seconds: Int,
	) throws {
		let time: ClockTime = try #require(
			POSIX.strptime(string, format: "%Y-%m-%dT%H:%M:%SZ")
		)

		#expect(time.seconds == seconds)
	}


	@Test func strptimeは解釈できない文字列でnilを返す() {
		let format: String = "%Y-%m-%dT%H:%M:%SZ"

		#expect(POSIX.strptime("", format: format) == nil)
		#expect(POSIX.strptime("2030-03-10", format: format) == nil)
		#expect(POSIX.strptime("2030-03-10T07:00:00Z extra", format: format) == nil)
		#expect(POSIX.strptime("2030-13-10T07:00:00Z", format: format) == nil)
	}


	@Test(arguments: [
		(0, "1970-01-01T00:00:00Z"),
		(978_307_200, "2001-01-01T00:00:00Z"),
		(1_899_356_400, "2030-03-10T07:00:00Z"),
		(-1, "1969-12-31T23:59:59Z"),
	])
	func strftimeは時刻をUTCの書式で文字列にする(
		seconds: Int,
		string: String,
	) {
		#expect(POSIX.strftime(.clock(seconds), format: "%Y-%m-%dT%H:%M:%SZ") == string)
	}


	@Test func strftimeはさまざまな書式に対応する() {
		let time: ClockTime = .clock(1_899_356_400)

		#expect(POSIX.strftime(time, format: "%Y%m%d") == "20300310")
		#expect(POSIX.strftime(time, format: "%H:%M") == "07:00")
		#expect(POSIX.strftime(time, format: "%j") == "069")
		#expect(POSIX.strftime(time, format: "%%") == "%")
		#expect(POSIX.strftime(time, format: "") == "")
	}


	@Test func strftimeは長い結果も切り詰めない() {
		let format: String = String(repeating: "%Y-%m-%d ", count: 1000)

		let result: String? = POSIX.strftime(.clock(0), format: format)

		#expect(result == String(repeating: "1970-01-01 ", count: 1000))
	}


	@Test(arguments: [
		"%Y-%m-%dT%H:%M:%SZ",
		"%Y/%m/%d %H:%M:%S",
		"%Y%m%d%H%M%S",
	])
	func strftimeとstrptimeは往復できる(
		format: String,
	) throws {
		for seconds in [0, 86_399, 951_782_400, 1_709_208_000, 2_145_916_799] {
			let time: ClockTime = .clock(seconds)
			let string: String? = POSIX.strftime(time, format: format)

			#expect(
				try #require(POSIX.strptime(string ?? "", format: format)).seconds == seconds,
				"\(format) \(string ?? "")",
			)
		}
	}

}
