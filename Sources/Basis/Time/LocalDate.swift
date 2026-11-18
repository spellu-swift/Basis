

///
/// ローカルカレンダーの日付
///
@Orderable
public struct LocalDate : Sendable {
	
	public init(
		year: Int,
		month: Int,
		day: Int,
	) {
		self.year = year
		self.month = month
		self.day = day
	}
	
	/// The year.
	public var year: Int
	
	/// The month-of-year.
	public var month: Int
	
	/// The day-of-month.
	public var day: Int
	
	public enum ResolverStyle {
		case strict
		case smart
		case lenient
	}
	
}


extension LocalDate {
	
	public static let MIN: LocalDate
	= .init(year: Year.MIN_VALUE, month: 1, day: 1)
	
	public static let MAX: LocalDate
	= .init(year: Year.MAX_VALUE, month: 12, day: 31)
	
	public static let EPOCH: LocalDate
	= .init(year: 1970, month: 1, day: 1)
	
}


extension LocalDate {

	/// Obtains the current date from the system clock in the default time-zone.
	@inlinable
	public static var now: LocalDate {
		.date(.now, zone: TimeZone.system)
	}
	
	/// Obtains the current date-time from the system clock in the specified time-zone.
	@inlinable
	public static func now(
		zone: TimeZone,
	) -> LocalDate {
		.date(.now, zone: zone)
	}

	@inlinable
	public static func date(
		_ year: Int,
		_ month: Int,
		_ day: Int,
		resolverStyle: ResolverStyle = .smart,
	) -> Self {
		// TODO: resolverStyleを使って補正する
		_ = resolverStyle
		
		return .init(
			year: year,
			month: month,
			day: day,
		)
	}
	
	@inlinable
	public static func date(
		_ clock: ClockTime,
		zone: TimeZone,
	) -> Self {
		.date(clock, offset: zone.offset(at: clock).totalSeconds)
	}
	
	public static func date(
		_ clock: ClockTime,
		offset: Int,
	) -> LocalDate {
		let localSecond: Int
		= clock.seconds + offset
		
		let epochDay: Int
		= localSecond / SECONDS_PER_DAY - (localSecond % SECONDS_PER_DAY < 0 ? 1 : 0)
		
		return date(epochDay: epochDay)
	}
	
	public static func date(
		epochDay: Int,
	) -> Self {
		let dayNumber = epochDay + Self.unixEpochDayNumber
		
		// 負の日数も、400年周期内の位置を0以上に揃える。
		let cycles = Self.floorDivide(dayNumber, by: DAYS_PER_CYCLE)
		var remaining = dayNumber - cycles * DAYS_PER_CYCLE

		// 周期の最終日は次の周期へ進めず、末尾の閏年に含める。
		let centuries = min(remaining / 36524, 3)
		remaining -= centuries * 36524
		
		let fourYears = remaining / 1461
		remaining -= fourYears * 1461

		let years = min(remaining / 365, 3)
		remaining -= years * 365

		let year = cycles * 400 + centuries * 100 + fourYears * 4 + years + 1
		let days = Self.daysBeforeMonth(leapYear: Self.isLeapYear(prolepticYear: year))

		var month = 1
		while remaining >= days[month] {
			month += 1
		}
		
		return .init(year: year, month: month, day: remaining - days[month - 1] + 1)
	}
	
}


extension LocalDate {
	
	public var epochDay: Int {
		let precedingYear = year - 1
		let daysBeforeYear = 365 * precedingYear
			+ Self.floorDivide(precedingYear, by: 4)
			- Self.floorDivide(precedingYear, by: 100)
			+ Self.floorDivide(precedingYear, by: 400)
		let days = Self.daysBeforeMonth(leapYear: isLeapYear)

		return daysBeforeYear + days[month - 1] + day - 1 - Self.unixEpochDayNumber
	}

	@inlinable
	public var isLeapYear: Bool {
		return Self.isLeapYear(prolepticYear: year)
	}
		
	public static func isLeapYear(
		prolepticYear: Int,
	) -> Bool {
		(prolepticYear & 3) == 0
		&& (prolepticYear % 100) != 0 || (prolepticYear % 400) == 0
	}
		
	@inlinable
	public var asClockTime: ClockTime {
		.clock(epochDay * SECONDS_PER_DAY, 0)
	}
		
}


extension LocalDate : Hashable {}


extension LocalDate : Codable {}


extension LocalDate : CustomStringConvertible {
	
	public var description: String {
		POSIX.format("%04d-%02d-%02d", year, month, day)
	}
		
}


public func compare(
	_ lhs: LocalDate,
	_ rhs: LocalDate,
) -> Ordering {
	compare(lhs, rhs, \.year)
		.else { compare(lhs, rhs, \.month) }
		.else { compare(lhs, rhs, \.day) }
}


private extension LocalDate {

	// 0001年1月1日を0とする日数でのUnix epoch。
	static let unixEpochDayNumber = 719162

	static let commonYearDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
	static let leapYearDays = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]

	static func daysBeforeMonth(leapYear: Bool) -> [Int] {
		leapYear ? leapYearDays : commonYearDays
	}

	// Swiftの整数除算は0方向へ丸めるため、負の年では切り下げに補正する。
	static func floorDivide(_ value: Int, by divisor: Int) -> Int {
		value / divisor - (value % divisor < 0 ? 1 : 0)
	}

}
