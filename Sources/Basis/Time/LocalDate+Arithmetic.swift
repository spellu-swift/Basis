

extension LocalDate {

	/// 日数を加算する。負数も指定でき、対応範囲を超えた場合はエラーにする。
	public func plus(
		days: Int,
	) throws -> Self {
		try shiftDays(days)
	}

	public func minus(
		days: Int,
	) throws -> Self {
		try shiftDays(days, subtract: true)
	}

	/// 月を加算する。smartは月末へ補正し、strictはエラー、lenientは翌月へ繰り越す。
	public func plus(
		months: Int,
		resolverStyle: ResolverStyle = .smart,
	) throws -> Self {
		try shiftMonths(months, resolverStyle: resolverStyle)
	}

	public func minus(
		months: Int,
		resolverStyle: ResolverStyle = .smart,
	) throws -> Self {
		try shiftMonths(months, subtract: true, resolverStyle: resolverStyle)
	}

	public func plus(
		years: Int,
		resolverStyle: ResolverStyle = .smart,
	) throws -> Self {
		try shiftYears(years, resolverStyle: resolverStyle)
	}

	public func minus(
		years: Int,
		resolverStyle: ResolverStyle = .smart,
	) throws -> Self {
		try shiftYears(
			years,
			subtract: true,
			resolverStyle: resolverStyle,
		)
	}

	/// 相手の日付から自分の日付を引いた、符号付きの日数。
	public func days(
		until other: Self,
	) -> Int {
		precondition(isValidCalendarDate && other.isValidCalendarDate)
		return other.epochDay - epochDay
	}

	public var daysInMonth: Int {
		precondition(Year.MIN_VALUE <= year && year <= Year.MAX_VALUE && (1...12).contains(month))

		switch month {
			case 2: return isLeapYear ? 29 : 28
			case 4, 6, 9, 11: return 30
			default: return 31
		}
	}

	public var startOfMonth: Self {
		_ = daysInMonth
		return .init(year: year, month: month, day: 1)
	}

	public var endOfMonth: Self {
		.init(year: year, month: month, day: daysInMonth)
	}

	public var dayOfWeek: DayOfWeek {
		precondition(isValidCalendarDate)
		// Unix epochは木曜日（rawValue: 5）。負の日数も0以上の剰余に揃える。
		return DayOfWeek(rawValue: ((epochDay + 4) % 7 + 7) % 7 + 1)!
	}

	var isValidCalendarDate: Bool {
		guard Year.MIN_VALUE <= year && year <= Year.MAX_VALUE && (1...12).contains(month)
		else { return false }
		return (1...daysInMonth).contains(day)
	}

	func validateCalendarDate() throws {
		guard isValidCalendarDate else { throw CalendarArithmeticError.invalidDate(self) }
	}

}


private extension LocalDate {

	func shiftDays(
		_ amount: Int,
		subtract: Bool = false,
	) throws -> Self {
		try validateCalendarDate()
		let target = try CalendarArithmetic.add(epochDay, amount, subtract: subtract)
		guard Self.MIN.epochDay <= target && target <= Self.MAX.epochDay
		else { throw CalendarArithmeticError.outOfRange }

		return .date(epochDay: target)
	}

	func shiftMonths(
		_ amount: Int,
		subtract: Bool = false,
		resolverStyle: ResolverStyle,
	) throws -> Self {
		try validateCalendarDate()
		let total = try CalendarArithmetic.add(year * 12 + month - 1, amount, subtract: subtract)
		let targetYear = CalendarArithmetic.floorDivide(total, by: 12)
		let targetMonth = (total % 12 + 12) % 12 + 1

		return try resolve(year: targetYear, month: targetMonth, resolverStyle: resolverStyle)
	}

	func shiftYears(
		_ amount: Int,
		subtract: Bool = false,
		resolverStyle: ResolverStyle,
	) throws -> Self {
		try validateCalendarDate()
		let targetYear = try CalendarArithmetic.add(year, amount, subtract: subtract)

		return try resolve(year: targetYear, month: month, resolverStyle: resolverStyle)
	}

	func resolve(
		year: Int,
		month: Int,
		resolverStyle: ResolverStyle,
	) throws -> Self {
		guard Year.MIN_VALUE <= year && year <= Year.MAX_VALUE
		else { throw CalendarArithmeticError.outOfRange }

		let first: Self = .init(year: year, month: month, day: 1)

		switch resolverStyle {
			case .smart:
				return .init(year: year, month: month, day: min(day, first.daysInMonth))

			case .strict:
				let result: Self = .init(year: year, month: month, day: day)
				try result.validateCalendarDate()
				return result

			case .lenient:
				return try first.plus(days: day - 1)
		}
	}

}
