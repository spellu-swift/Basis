
extension LocalDateTime {

	/// 日付を変更し、時刻は保持する。
	public func plus(
		years: Int,
		resolverStyle: LocalDate.ResolverStyle = .smart,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.plus(years: years, resolverStyle: resolverStyle), time: time)
	}

	public func minus(
		years: Int,
		resolverStyle: LocalDate.ResolverStyle = .smart,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.minus(years: years, resolverStyle: resolverStyle), time: time)
	}

	public func plus(
		months: Int,
		resolverStyle: LocalDate.ResolverStyle = .smart,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.plus(months: months, resolverStyle: resolverStyle), time: time)
	}

	public func minus(
		months: Int,
		resolverStyle: LocalDate.ResolverStyle = .smart,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.minus(months: months, resolverStyle: resolverStyle), time: time)
	}

	public func plus(
		days: Int,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.plus(days: days), time: time)
	}

	public func minus(
		days: Int,
	) throws -> Self {
		try validateCalendarTime()
		return .init(date: try date.minus(days: days), time: time)
	}

	/// 1日を24時間として計算し、日付への繰り上がり・繰り下がりを行う。
	public func plus(
		hours: Int,
	) throws -> Self {
		try shiftTime(hours, unitsPerDay: 24, nanosPerUnit: NANOS_PER_HOUR)
	}

	public func minus(
		hours: Int,
	) throws -> Self {
		try shiftTime(hours, unitsPerDay: 24, nanosPerUnit: NANOS_PER_HOUR, subtract: true)
	}

	public func plus(
		minutes: Int,
	) throws -> Self {
		try shiftTime(minutes, unitsPerDay: 1440, nanosPerUnit: NANOS_PER_MINUTE)
	}

	public func minus(
		minutes: Int,
	) throws -> Self {
		try shiftTime(minutes, unitsPerDay: 1440, nanosPerUnit: NANOS_PER_MINUTE, subtract: true)
	}

	public func plus(
		seconds: Int,
	) throws -> Self {
		try shiftTime(seconds, unitsPerDay: SECONDS_PER_DAY, nanosPerUnit: NANOS_PER_SECOND)
	}

	public func minus(
		seconds: Int,
	) throws -> Self {
		try shiftTime(seconds, unitsPerDay: SECONDS_PER_DAY, nanosPerUnit: NANOS_PER_SECOND, subtract: true)
	}

	public func plus(
		nanos: Int,
	) throws -> Self {
		try shiftTime(nanos, unitsPerDay: CalendarArithmetic.nanosPerDay, nanosPerUnit: 1)
	}

	public func minus(
		nanos: Int,
	) throws -> Self {
		try shiftTime(nanos, unitsPerDay: CalendarArithmetic.nanosPerDay, nanosPerUnit: 1, subtract: true)
	}

	/// ナノ秒未満は0方向へ切り捨てる。タイムゾーン・夏時間の補正は行わない。
	public func plus(
		_ duration: Duration,
	) throws -> Self {
		try shiftDuration(duration)
	}

	public func minus(
		_ duration: Duration,
	) throws -> Self {
		try shiftDuration(duration, subtract: true)
	}

	/// 相手の日時から自分の日時を引いたDuration。1日は24時間として扱う。
	public func duration(
		until other: Self,
	) -> Duration {
		precondition(isValidCalendarDateTime && other.isValidCalendarDateTime)
		let seconds = date.days(until: other.date) * SECONDS_PER_DAY
			+ other.time.secondOfDay - time.secondOfDay

		return .seconds(seconds) + .nanoseconds(other.time.nano - time.nano)
	}
}


private extension LocalDateTime {

	var isValidCalendarTime: Bool {
		(0..<24).contains(time.hour)
			&& (0..<60).contains(time.minute)
			&& (0..<60).contains(time.second)
			&& (0..<NANOS_PER_SECOND).contains(time.nano)
	}

	var isValidCalendarDateTime: Bool {
		date.isValidCalendarDate && isValidCalendarTime
	}

	func validateCalendarTime() throws {
		guard isValidCalendarTime else { throw CalendarArithmeticError.invalidTime(time) }
	}

	func shiftTime(
		_ amount: Int,
		unitsPerDay: Int,
		nanosPerUnit: Int,
		subtract: Bool = false,
	) throws -> Self {
		// amountを先に分解し、大きな入力をナノ秒へ直接乗算しない。
		let days = amount / unitsPerDay
		let nanos = (amount % unitsPerDay) * nanosPerUnit

		return try shifted(days: subtract ? -days : days, nanos: subtract ? -nanos : nanos)
	}

	// この限界より大きいDurationは、どの日時に加減算しても対応範囲外。
	// componentsの秒数がInt64に収まらないDurationも、分解する前に拒否する。
	static let durationLimit: Duration = .seconds(
		(LocalDate.MAX.epochDay - LocalDate.MIN.epochDay + 1) * SECONDS_PER_DAY
	)

	func shiftDuration(
		_ duration: Duration,
		subtract: Bool = false,
	) throws -> Self {
		try date.validateCalendarDate()
		try validateCalendarTime()
		guard duration < Self.durationLimit && duration > .zero - Self.durationLimit
		else { throw CalendarArithmeticError.outOfRange }

		let components = duration.components
		let seconds = Int(components.seconds)
		let days = seconds / SECONDS_PER_DAY
		let nanos = (seconds % SECONDS_PER_DAY) * NANOS_PER_SECOND
			+ Int(components.attoseconds / 1_000_000_000)

		return try shifted(
			days: subtract ? -days : days,
			nanos: subtract ? -nanos : nanos,
		)
	}

	func shifted(
		days: Int,
		nanos: Int,
	) throws -> Self {
		try date.validateCalendarDate()
		try validateCalendarTime()
		let total = try CalendarArithmetic.add(time.nanoOfDay, nanos)
		let carry = CalendarArithmetic.floorDivide(total, by: CalendarArithmetic.nanosPerDay)
		let remainder = total % CalendarArithmetic.nanosPerDay
		let nanosOfDay = remainder < 0 ? remainder + CalendarArithmetic.nanosPerDay : remainder
		let dayShift = try CalendarArithmetic.add(days, carry)

		return .init(
			date: try date.plus(days: dayShift),
			time: .time(nanoOfDay: nanosOfDay),
		)
	}

}
