@testable import Basis


@Test(arguments: [-86401, -86400, -86399, -1, 0, 1, 86399, 86400])
func epoch_conversion_matches_java_floor_arithmetic(seconds: Int) {
	for offset in [-32400, 0, 32400] {
		let clock: ClockTime = .clock(seconds, 123456789)
		let local: LocalDateTime = .dateTime(clock, offset: offset)

		#expect(local.time.secondOfDay >= 0)
		#expect(local.time.secondOfDay < 86400)
		#expect(local.date.epochDay * 86400 + local.time.secondOfDay - offset == seconds)
		#expect(local.time.nano == clock.nano)
		#expect(.date(clock, offset: offset) == local.date)
		#expect(.time(clock, offset: offset) == local.time)
	}
}


@Test
func second_before_epoch() {
	let local: LocalDateTime = .dateTime(.clock(-1), offset: 0)

	#expect(local == .dateTime(1969, 12, 31, 23, 59, 59))
}
