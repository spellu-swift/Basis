

///
/// ローカルカレンダーの時刻
///
@Orderable
public struct LocalTime : Sendable {
	
	public init(
		hour: Int,
		minute: Int,
		second: Int,
		nano: Int,
	) {
		self.hour = hour
		self.minute = minute
		self.second = second
		self.nano = nano
	}

	public var hour: Int
	
	public var minute: Int
	
	public var second: Int
	
	public var nano: Int
	
}


extension LocalTime {
	
	public static let MIN: LocalTime
	= .init(hour: 0, minute: 0, second: 0, nano: 0)
	
	public static let MAX: LocalTime
	= .init(hour: 23, minute: 59, second: 59, nano: 999_999_999)
	
	public static let MIDNIGHT: LocalTime
	= .init(hour: 0, minute: 0, second: 0, nano: 0)
	
	public static let NOON: LocalTime
	= .init(hour: 12, minute: 0, second: 0, nano: 0)
	
}


extension LocalTime {

	/// Obtains the current date from the system clock in the default time-zone.
	@inlinable
	public static var now: LocalTime {
		.time(.now, zone: TimeZone.system)
	}
	
	/// Obtains the current date-time from the system clock in the specified time-zone.
	@inlinable
	public static func now(
		zone: TimeZone,
	) -> LocalTime {
		.time(.now, zone: zone)
	}
	
	@inlinable
	public static func time(
		_ hour: Int,
		_ minute: Int,
		_ second: Int,
		nano: Int = 0,
	) -> Self {
		.init(
			hour: hour,
			minute: minute,
			second: second,
			nano: nano,
		)
	}
	
	@inlinable
	public static func time(
		_ clock: ClockTime,
		zone: TimeZone,
	) -> Self {
		.time(clock, offset: zone.offset(at: clock).totalSeconds)
	}
	
	public static func time(
		_ clock: ClockTime,
		offset: Int,
	) -> Self {
		let localSecond: Int = clock.seconds + offset
		
		let secondsOfDay = (localSecond % SECONDS_PER_DAY + SECONDS_PER_DAY) % SECONDS_PER_DAY
		
		return .time(seconds: secondsOfDay, nano: clock.nano)
	}
	
	public static func time(
		seconds: Int,
		nano: Int = 0,
	) -> Self {
		var remain: Int = seconds
		
		let hours: Int = remain / SECONDS_PER_HOUR
		remain -= hours * SECONDS_PER_HOUR
		
		let minutes: Int = remain / SECONDS_PER_MINUTE
		remain -= minutes * SECONDS_PER_MINUTE
		
		return .init(
			hour: hours,
			minute: minutes,
			second: remain,
			nano: nano,
		)
	}
	
	public static func time(
		nanoOfDay: Int,
	) -> Self {
		var remain: Int = nanoOfDay
		
		let hours: Int = remain / NANOS_PER_HOUR
		remain -= hours * NANOS_PER_HOUR
		
		let minutes: Int = remain / NANOS_PER_MINUTE
		remain -= minutes * NANOS_PER_MINUTE
		
		let seconds: Int = remain / NANOS_PER_SECOND
		remain -= seconds * NANOS_PER_SECOND
		
		return .init(
			hour: hours,
			minute: minutes,
			second: seconds,
			nano: remain,
		)
	}
	
}


extension LocalTime {
		
	public var secondOfDay: Int {
		var total: Int = 0
		total += hour * SECONDS_PER_HOUR
		total += minute * SECONDS_PER_MINUTE
		total += second
		return total
	}
		
	public var nanoOfDay: Int {
		var total: Int = 0
		total += hour * NANOS_PER_HOUR
		total += minute * NANOS_PER_MINUTE
		total += second * NANOS_PER_SECOND
		total += nano
		return total
	}
		
}


extension LocalTime : Hashable {}


extension LocalTime : Codable {}


extension LocalTime : CustomStringConvertible {
	
	public var description: String {
		POSIX.format("%02d:%02d:%02d.%06d", hour, minute, second, nano / 1_000)
	}
	
}


public func compare(
	_ lhs: LocalTime,
	_ rhs: LocalTime,
) -> Ordering {
	compare(lhs, rhs, \.hour)
		.else { compare(lhs, rhs, \.minute) }
		.else { compare(lhs, rhs, \.second) }
		.else { compare(lhs, rhs, \.nano) }
}

