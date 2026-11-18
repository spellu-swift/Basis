

///
/// ローカルカレンダーの日付と時刻
///
@Orderable
public struct LocalDateTime : Sendable {
	
	@inlinable
	public init(
		date: LocalDate,
		time: LocalTime,
	) {
		self.date = date
		self.time = time
	}
	
	public var date: LocalDate
	
	public var time: LocalTime
	
}


extension LocalDateTime {
	
	public static let MIN: LocalDateTime
	= .init(date: LocalDate.MIN, time: LocalTime.MIN)
	
	public static let MAX: LocalDateTime
	= .init(date: LocalDate.MAX, time: LocalTime.MAX)
	
	public static let EPOCH: LocalDateTime
	= .init(date: LocalDate.EPOCH, time: LocalTime.MIN)
	
}


extension LocalDateTime {

	///  現在時刻
	@inlinable
	public static var now: LocalDateTime {
		.dateTime(.now, zone: TimeZone.system)
	}
	
	///  現在時刻
	@inlinable
	public static func now(
		zone: TimeZone,
	) -> LocalDateTime {
		.dateTime(.now, zone: zone)
	}

	@inlinable
	public static func dateTime(
		_ year: Int,
		_ month: Int,
		_ day: Int,
		_ hour: Int,
		_ minute: Int,
		_ second: Int,
		nano: Int = 0
	) -> Self {
		.init(
			date: .date(year, month, day),
			time: .time(hour, minute, second, nano: nano),
		)
	}
	
	@inlinable
	public static func dateTime(
		_ date: LocalDate,
		_ time: LocalTime,
	) -> Self {
		.init(
			date: date,
			time: time,
		)
	}
	
	@inlinable
	public static func dateTime(
		_ clock: ClockTime,
		zone: TimeZone,
	) -> Self {
		.dateTime(
			clock,
			offset: zone.offset(at: clock).totalSeconds,
		)
	}
	
	public static func dateTime(
		_ clock: ClockTime,
		offset: Int,
	) -> Self {
		let localSecond: Int = clock.seconds + offset
		
		let epochDay: Int = localSecond / SECONDS_PER_DAY - (localSecond % SECONDS_PER_DAY < 0 ? 1 : 0)
		let secondsOfDay = (localSecond % SECONDS_PER_DAY + SECONDS_PER_DAY) % SECONDS_PER_DAY
		
		return .dateTime(
			.date(epochDay: epochDay),
			.time(seconds: secondsOfDay, nano: clock.nano),
		)
	}
	
}


extension LocalDateTime {

	@inlinable
	public func epochSecond(
		zone: TimeZone,
	) -> Int {
		zone.epochSecond(for: self)
	}
		
	@inlinable
	public func asClockTime(
		zone: TimeZone,
	) -> ClockTime {
		.clock(epochSecond(zone: zone), time.nano)
	}
	
}


extension LocalDateTime : Hashable {}


extension LocalDateTime : Codable {}


extension LocalDateTime : CustomStringConvertible {
	
	public var description: String {
		"\(date.description)T\(time.description)"
	}
	
}
