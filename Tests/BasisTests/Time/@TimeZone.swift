@testable import Basis


@Suite struct TimeZoneTests {

	@Test
	func summer_and_winter_offsets() throws {
		let zone: TimeZone = try .named("America/New_York")
		let winter: ClockTime = .clock(1577836800)
		let summer: ClockTime = .clock(1593561600, 123456789)

		#expect(zone.offset(at: winter).totalSeconds == -18000)
		#expect(zone.offset(at: summer).totalSeconds == -14400)
		#expect(LocalDateTime.dateTime(winter, zone: zone) == .dateTime(2019, 12, 31, 19, 0, 0))

		let local: LocalDateTime = .dateTime(summer, zone: zone)

		#expect(local == .dateTime(2020, 6, 30, 20, 0, 0, nano: 123456789))
		#expect(local.asClockTime(zone: zone) == summer)
		#expect(LocalDate.date(summer, zone: zone) == local.date)
		#expect(LocalTime.time(summer, zone: zone) == local.time)
		#expect(ZonedDateTime.dateTime(local, zone: zone).description.contains("-04:00[America/New_York]"))
	}


	@Test
	func zero_offset_region_keeps_its_name() throws {
		let zone: TimeZone = try .named("Europe/London")

		#expect(zone.name == "Europe/London")
		#expect(zone.offset(at: .clock(1577836800)).totalSeconds == 0)
		#expect(zone.offset(at: .clock(1593561600)).totalSeconds == 3600)
	}


	@Test
	func gap_moves_forward_and_overlap_chooses_earlier() throws {
		let zone: TimeZone = try .named("America/New_York")
		let gap = LocalDateTime.dateTime(2020, 3, 8, 2, 30, 0, nano: 123456789)
		let overlap = LocalDateTime.dateTime(2020, 11, 1, 1, 30, 0)

		#expect(gap.epochSecond(zone: zone) == 1583652600)
		#expect(ZonedDateTime.dateTime(gap, zone: zone).dateTime == .dateTime(2020, 3, 8, 3, 30, 0, nano: 123456789))
		#expect(overlap.epochSecond(zone: zone) == 1604208600)
	}


	@Test
	func half_hour_gap_and_skipped_day() throws {
		let halfHour: TimeZone = try .named("Australia/Lord_Howe")
		let gap = LocalDateTime.dateTime(2020, 10, 4, 2, 15, 0)

		#expect(ZonedDateTime.dateTime(gap, zone: halfHour).dateTime == .dateTime(2020, 10, 4, 2, 45, 0))

		let apia: TimeZone = try .named("Pacific/Apia")
		let skipped = LocalDateTime.dateTime(2011, 12, 30, 12, 0, 0)

		#expect(ZonedDateTime.dateTime(skipped, zone: apia).dateTime == .dateTime(2011, 12, 31, 12, 0, 0))
	}

	@Test(arguments: [-999999999, -20000, 0, 1500, 1970, 999999999])
	func proleptic_gregorian_roundtrip(year: Int) {
		let local: LocalDateTime = .dateTime(year, 3, 1, 12, 34, 56, nano: 123456789)
		let clock: ClockTime = local.asClockTime(zone: .utc)

		#expect(LocalDateTime.dateTime(clock, zone: .utc) == local)
	}

	@Test
	func historical_date_roundtrip() throws {
		let zone: TimeZone = try .named("Europe/London")
		let local: LocalDateTime = .dateTime(1500, 3, 1, 12, 34, 56)

		#expect(LocalDateTime.dateTime(local.asClockTime(zone: zone), zone: zone) == local)
	}

}
