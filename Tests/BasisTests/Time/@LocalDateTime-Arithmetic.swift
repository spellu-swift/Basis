@testable import Basis


@Test
func localDateTime_calendar_units_preserve_time() throws {
	let dateTime: LocalDateTime = .dateTime(2025, 1, 31, 23, 30, 0, nano: 123)
	#expect(try dateTime.plus(months: 1) == .dateTime(2025, 2, 28, 23, 30, 0, nano: 123))
	#expect(try dateTime.plus(months: 1, resolverStyle: .lenient).date == .date(2025, 3, 3))
	#expect(throws: CalendarArithmeticError.self) { try dateTime.plus(months: 1, resolverStyle: .strict) }
	#expect(try dateTime.minus(months: 1).date == .date(2024, 12, 31))
	#expect(try dateTime.plus(years: 1).time == dateTime.time)
	#expect(try dateTime.minus(years: 1).date == .date(2024, 1, 31))
	#expect(try dateTime.plus(days: 1).date == .date(2025, 2, 1))
	#expect(try dateTime.minus(days: 1).time == dateTime.time)

	let leap: LocalDateTime = .dateTime(2024, 2, 29, 12, 0, 0)
	#expect(try leap.plus(years: 1).date == .date(2025, 2, 28))
	#expect(try leap.minus(years: 1, resolverStyle: .lenient).date == .date(2023, 3, 1))
	#expect(throws: CalendarArithmeticError.self) { try leap.minus(years: 1, resolverStyle: .strict) }
}


@Test
func localDateTime_time_units_cross_day_and_year_boundaries() throws {
	let dateTime: LocalDateTime = .dateTime(2025, 1, 31, 23, 30, 0)
	#expect(try dateTime.plus(hours: 2) == .dateTime(2025, 2, 1, 1, 30, 0))
	#expect(try dateTime.plus(minutes: 90) == .dateTime(2025, 2, 1, 1, 0, 0))
	#expect(try dateTime.plus(seconds: 1801) == .dateTime(2025, 2, 1, 0, 0, 1))
	#expect(try dateTime.minus(hours: 24) == dateTime.minus(days: 1))
	#expect(try dateTime.minus(minutes: -90) == dateTime.plus(minutes: 90))

	let midnight: LocalDateTime = .dateTime(0, 1, 1, 0, 0, 0)
	#expect(try midnight.minus(seconds: 1) == .dateTime(-1, 12, 31, 23, 59, 59))
	#expect(try midnight.minus(nanos: 1) == .dateTime(-1, 12, 31, 23, 59, 59, nano: 999_999_999))
	#expect(try midnight.plus(nanos: -1).plus(nanos: 1) == midnight)
}


@Test
func localDateTime_duration_is_signed_and_exact_across_supported_range() throws {
	let earlier: LocalDateTime = .dateTime(2024, 2, 28, 23, 59, 59, nano: 900_000_000)
	let later: LocalDateTime = .dateTime(2024, 2, 29, 0, 0, 0, nano: 100_000_000)
	#expect(earlier.duration(until: later) == .milliseconds(200))
	#expect(later.duration(until: earlier) == .milliseconds(-200))
	#expect(earlier.duration(until: earlier) == .zero)
	#expect(try earlier.plus(.milliseconds(200)) == later)
	#expect(try later.minus(.milliseconds(200)) == earlier)

	let span = LocalDateTime.MIN.duration(until: .MAX)
	#expect(try LocalDateTime.MIN.plus(span) == .MAX)
	#expect(try LocalDateTime.MAX.minus(span) == .MIN)
	#expect(try LocalDateTime.MAX.plus(.zero - span) == .MIN)
}


@Test
func localDateTime_duration_discards_subnanosecond_fraction() throws {
	let half: Duration = .init(secondsComponent: 0, attosecondsComponent: 500_000_000)
	#expect(try LocalDateTime.MIN.minus(half) == .MIN)
	#expect(try LocalDateTime.MAX.plus(half) == .MAX)
	#expect(try LocalDateTime.EPOCH.plus(.nanoseconds(1) + half) == .EPOCH.plus(nanos: 1))
	#expect(try LocalDateTime.EPOCH.minus(.nanoseconds(1) + half) == .EPOCH.minus(nanos: 1))
}


@Test
func localDateTime_nanoseconds_accept_full_integer_range() throws {
	for nanos in [Int.min, Int.max] {
		let forward = try LocalDateTime.EPOCH.plus(nanos: nanos)
		let backward = try LocalDateTime.EPOCH.minus(nanos: nanos)
		#expect(try forward.minus(nanos: nanos) == .EPOCH)
		#expect(try backward.plus(nanos: nanos) == .EPOCH)
		#expect((0..<NANOS_PER_SECOND).contains(forward.time.nano))
		#expect((0..<NANOS_PER_SECOND).contains(backward.time.nano))
	}
}


@Test
func localDateTime_arithmetic_reports_bounds_without_trapping() throws {
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.MIN.minus(nanos: 1) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.MAX.plus(nanos: 1) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.MAX.plus(.nanoseconds(1)) }

	for amount in [Int.min, Int.max] {
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.plus(hours: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.minus(hours: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.plus(minutes: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.minus(minutes: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.plus(seconds: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.EPOCH.minus(seconds: amount) }
	}
	let huge: Duration = .seconds(UInt64.max)
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.EPOCH.plus(huge) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.EPOCH.minus(huge) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDateTime.EPOCH.plus(.zero - huge) }
	#expect(throws: CalendarArithmeticError.self) { try LocalDateTime.dateTime(2025, 1, 1, 24, 0, 0).plus(seconds: 0) }
}
