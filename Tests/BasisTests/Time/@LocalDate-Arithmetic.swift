@testable import Basis


@Test
func localDate_month_and_year_resolution() throws {
	let january: LocalDate = .date(2025, 1, 31)
	#expect(try january.plus(months: 1) == .date(2025, 2, 28))
	#expect(try january.plus(months: 1, resolverStyle: .lenient) == .date(2025, 3, 3))
	#expect(throws: CalendarArithmeticError.self) {
		try january.plus(months: 1, resolverStyle: .strict)
	}
	#expect(try january.plus(months: 2) == .date(2025, 3, 31))
	#expect(try january.plus(months: 1).plus(months: 1) == .date(2025, 3, 28))

	let leap: LocalDate = .date(2024, 2, 29)
	#expect(try leap.plus(years: 1) == .date(2025, 2, 28))
	#expect(try leap.plus(years: 1, resolverStyle: .lenient) == .date(2025, 3, 1))
	#expect(throws: CalendarArithmeticError.self) {
		try leap.plus(years: 1, resolverStyle: .strict)
	}
	#expect(try leap.minus(years: 4, resolverStyle: .strict) == .date(2020, 2, 29))
	#expect(try leap.minus(months: -12) == leap.plus(years: 1))
}


@Test
func localDate_days_signed_year_zero_and_negative_years() throws {
	let epoch: LocalDate = .EPOCH
	#expect(try epoch.minus(days: 1) == .date(1969, 12, 31))
	#expect(try epoch.plus(days: -1) == epoch.minus(days: 1))
	#expect(epoch.days(until: .date(1970, 1, 2)) == 1)
	#expect(epoch.days(until: .date(1969, 12, 31)) == -1)
	#expect(epoch.days(until: epoch) == 0)

	let zero: LocalDate = .date(0, 1, 31)
	#expect(try zero.minus(months: 1) == .date(-1, 12, 31))
	#expect(try zero.plus(months: 1) == .date(0, 2, 29))
	#expect(try zero.minus(years: -1) == .date(1, 1, 31))
}


@Test
func localDate_month_properties_and_weekdays() {
	let date: LocalDate = .date(2024, 2, 29)
	#expect(date.daysInMonth == 29)
	#expect(date.startOfMonth == .date(2024, 2, 1))
	#expect(date.endOfMonth == date)
	#expect(date.dayOfWeek == .thursday)
	#expect(LocalDate.date(1900, 2, 1).daysInMonth == 28)
	#expect(LocalDate.date(2000, 2, 1).daysInMonth == 29)
	#expect(LocalDate.date(0, 1, 1).dayOfWeek == .saturday)
	#expect(LocalDate.date(1, 1, 1).dayOfWeek == .monday)
	#expect(LocalDate.date(1969, 12, 31).dayOfWeek == .wednesday)
	#expect(LocalDate.EPOCH.dayOfWeek == .thursday)
}


@Test
func localDate_arithmetic_reports_range_and_integer_limits() throws {
	#expect(try LocalDate.MIN.plus(days: 1).minus(days: 1) == .MIN)
	#expect(try LocalDate.MAX.minus(days: 1).plus(days: 1) == .MAX)
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDate.MIN.minus(days: 1) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDate.MAX.plus(months: 1) }
	#expect(throws: CalendarArithmeticError.outOfRange) { try LocalDate.MIN.minus(years: 1) }

	for amount in [Int.min, Int.max] {
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.plus(days: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.minus(days: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.plus(months: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.minus(months: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.plus(years: amount) }
		#expect(throws: CalendarArithmeticError.self) { try LocalDate.EPOCH.minus(years: amount) }
	}
	#expect(throws: CalendarArithmeticError.self) { try LocalDate.date(2025, 2, 29).plus(days: 0) }
}
