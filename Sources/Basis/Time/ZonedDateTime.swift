

///
/// Zoneを持つDateTime
///
@Orderable
public struct ZonedDateTime : Sendable {
	
	public init(
		dateTime: LocalDateTime,
		zone: TimeZone,
	) {
		self.dateTime = dateTime
		self.zone = zone
	}

	public var dateTime: LocalDateTime
	
	public var zone: TimeZone
	
}


extension ZonedDateTime {
	
	public static let EPOCH: ZonedDateTime
	= .init(dateTime: LocalDateTime.EPOCH, zone: .utc)
	
}


extension ZonedDateTime {

	/// Obtains the current date from the system clock in the default time-zone.
	@inlinable
	public static var now: ZonedDateTime {
		now(zone: .system)
	}
	
	/// Obtains the current date-time from the system clock in the specified time-zone.
	@inlinable
	public static func now(
		zone: TimeZone,
	) -> Self {
		.init(
			dateTime: .now(zone: zone),
			zone: zone
		)
	}
	
	/// カレンダー要素からZonedDateTimeを生成する。
	@inlinable
	public static func dateTime(
		_ year: Int,
		_ month: Int,
		_ day: Int,
		_ hour: Int,
		_ minute: Int,
		_ second: Int,
		nano: Int = 0,
		zone: TimeZone = .utc,
	) -> Self {
		.dateTime(
			.dateTime(year, month, day, hour, minute, second, nano: nano),
			zone: zone,
		)
	}
	
	/// LocalDateとLocalTimeからZonedDateTimeを生成する。
	@inlinable
	public static func dateTime(
		_ date: LocalDate,
		_ time: LocalTime,
		zone: TimeZone,
	) -> Self {
		.dateTime(.dateTime(date, time), zone: zone)
	}
	
	/// LocalDateTimeからZonedDateTimeを生成する。
	@inlinable
	public static func dateTime(
		_ dateTime: LocalDateTime,
		zone: TimeZone,
	) -> Self {
		.init(
			dateTime: .dateTime(dateTime.asClockTime(zone: zone), zone: zone),
			zone: zone
		)
	}
	
}


extension ZonedDateTime {
	
	@inlinable
	public var date: LocalDate {
		dateTime.date
	}
	
	@inlinable
	public var time: LocalTime {
		dateTime.time
	}
	
	/// UTC
	@inlinable
	public var epochSecond: Int {
		return dateTime.epochSecond(zone: zone)
	}

	/// Local
	@inlinable
	public var asClockTime: ClockTime {
		.clock(dateTime.epochSecond(zone: zone), time.nano)
	}

}


extension ZonedDateTime : Hashable {}


extension ZonedDateTime : Codable {}


extension ZonedDateTime : CustomStringConvertible {
	
	@inlinable
	public var description: String {
		"\(dateTime.description)\(zone.offset(at: asClockTime).description)[\(zone.name)]"
	}
	
}
