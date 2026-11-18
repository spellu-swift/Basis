@testable import Basis


@Test
func clockTime_zoned_conversion_preserves_instant() throws {
	let zones: [TimeZone] = [
		.utc,
		try .named("Asia/Tokyo"),
		try .named("America/New_York"),
	]
	let clocks: [ClockTime] = [
		.EPOCH,
		.clock(-1, 500_000_000),
		ZonedDateTime.dateTime(2024, 7, 1, 12, 0, 0, zone: .utc).asClockTime,
		ZonedDateTime.dateTime(2024, 1, 1, 12, 0, 0, zone: .utc).asClockTime,
	]

	for clock in clocks {
		for zone in zones {
			let zoned = clock.asZonedDateTime(zone: zone)
			#expect(zoned.zone == zone)
			#expect(zoned.dateTime == clock.asLocalDateTime(zone: zone))
			#expect(zoned.asClockTime == clock)
		}
	}
}
