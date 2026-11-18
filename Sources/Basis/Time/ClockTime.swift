import Libc


@Orderable
public struct ClockTime : Sendable {
	
	@inlinable
	public init(
		seconds: POSIX.time_t,
		nano: Int,
	) {
		self.seconds = seconds
		self.nano = nano
	}
	
	public let seconds: POSIX.time_t
	
	public let nano: Int
	
	@inlinable
	public var micro: Int {
		nano / 1_000
	}
	
	@inlinable
	public var milli: Int {
		nano / 1_000_000
	}
	
	@inlinable
	public var asDouble: Double {
		Double(seconds) + Double(nano) / Double(NANOS_PER_SECOND)
	}
	
	/// クロックタイムの差分を取る
	@inlinable
	public func time(
		since: Self,
	) -> Duration {
		self - since
	}
	
}


extension ClockTime {
	
	public static let EPOCH: ClockTime
	= .init(seconds: 0, nano: 0)
	
	private static let MIN_SECOND: POSIX.time_t
	= -31557014167219200
	
	private static let MAX_SECOND: POSIX.time_t
	= 31556889864403199
	
	public static let MIN: ClockTime
	= .init(seconds: MIN_SECOND, nano: 0)
	
	public static let MAX: ClockTime
	= .init(seconds: MAX_SECOND, nano: 999_999_999)
	
	public static let at1970: ClockTime
	= .init(seconds: 0, nano: 0)
	
	public static let at2001: ClockTime
	= .init(seconds: between1970_2001, nano: 0)
	
	/// The number of seconds from 1 January 1970 to the reference date, 1 January 2001.
	public static let between1970_2001: Int
	= 978307200
	
}


extension ClockTime {

	/// 現在時刻(UTC)を取得する
	@inlinable
	public static var now: ClockTime {
		let time = POSIX.gettime()
		
		return .clock(
			time.tv_sec,
			time.tv_nsec,
		)
	}
	
	/// インスタンス生成
	public static func clock(
		_ seconds: Int,
		_ nano: Int = 0,
	) -> Self {
		precondition(MIN_SECOND <= seconds && seconds <= MAX_SECOND)
		
		return Self(
			seconds: seconds,
			nano: nano,
		)
	}
	
	/// インスタンス生成
	public static func clock(
		_ seconds: Double,
	) -> Self {
		guard let clock = Self.normalized(seconds: seconds)
		else { preconditionFailure("ClockTime seconds must be finite and within the supported range") }

		return clock
	}
	
	@inlinable
	public func of(
		base: Self,
		_ seconds: Int,
		_ nano: Int = 0,
	) -> Self {
		base.plus(seconds, nano)
	}
	
	@inlinable
	public func of(
		base: Self,
		_ seconds: Double,
	) -> Self {
		let values: (Int, Double) = seconds.splitted
		
		return base.plus(values.0, Int(values.1 * Double(NANOS_PER_SECOND)))
	}
	
}


private extension ClockTime {

	static func normalized(
		seconds: Double,
	) -> Self? {
		guard seconds.isFinite,
			seconds >= Double(MIN_SECOND),
			seconds <= Double(MAX_SECOND)
		else { return nil }

		// 秒を切り下げ、小数部を0以上のナノ秒にする。
		let wholeSeconds = Int(seconds.rounded(.down))
		guard MIN_SECOND <= wholeSeconds && wholeSeconds <= MAX_SECOND
		else { return nil }

		return .init(
			seconds: wholeSeconds,
			nano: Int((seconds - Double(wholeSeconds)) * Double(NANOS_PER_SECOND)),
		)
	}

}


extension ClockTime {
	
	/// クロックタイムの差分を取る
	@inlinable
	public static func - (
		_ lhs: Self,
		_ rhs: Self,
	) -> Duration {
		let secondsTotal: Int = lhs.seconds - rhs.seconds
		let nanosTotal: Int = lhs.nano - rhs.nano

		return .seconds(secondsTotal) + .nanoseconds(nanosTotal)
	}
	
}


extension ClockTime {

	@inlinable
	public static func + (
		_ self: Self,
		_ secondsToAdd: Int,
	) -> Self {
		self.plus(secondsToAdd, 0)
	}
	
	@inlinable
	public static func + (
		_ self: Self,
		_ secondsToAdd: Double,
	) -> Self {
		self.plus(.seconds(secondsToAdd))
	}
	
	@inlinable
	public static func - (
		_ self: Self,
		_ secondsToSubtract: Int,
	) -> Self {
		self.plus(-secondsToSubtract, 0)
	}
	
	@inlinable
	public static func - (
		_ self: Self,
		_ secondsToSubtract: Double,
	) -> Self {
		self.minus(.seconds(secondsToSubtract))
	}
	
	@inlinable
	public static func + (
		_ clock: Self,
		_ duration: Duration,
	) -> Self {
		clock.plus(duration)
	}

	@inlinable
	public static func - (
		_ clock: Self,
		_ duration: Duration,
	) -> Self {
		clock.minus(duration)
	}

	/// ナノ秒未満の時間量は0方向へ切り捨てる。
	@inlinable
	public func plus(
		_ durationToAdd: Duration,
	) -> Self {
		let components = durationToAdd.components

		return plus(Int(components.seconds), Int(components.attoseconds / 1_000_000_000))
	}
	
	/// ナノ秒未満の時間量は0方向へ切り捨てる。
	@inlinable
	public func minus(
		_ durationToSubtract: Duration,
	) -> Self {
		plus(.zero - durationToSubtract)
	}
	
	@inlinable
	public func plus(
		seconds secondsToAdd: Int,
	) -> Self {
		plus(secondsToAdd, 0)
	}
	
	@inlinable
	public func plus(
		nanos nanosToAdd: Int,
	) -> Self {
		plus(0, nanosToAdd)
	}
	
	@inlinable
	public func minus(
		seconds secondsToSubtract: Int,
	) -> Self {
		plus(-secondsToSubtract, 0)
	}
	
	@inlinable
	public func minus(
		nanos nanosToSubtract: Int,
	) -> Self {
		plus(0, -nanosToSubtract)
	}
		
	@usableFromInline
	internal func plus(
		_ secondsToAdd: Int,
		_ nanosToAdd: Int,
	) -> Self {
		if (secondsToAdd | nanosToAdd) == 0 {
			return self
		}

		let nanosTotal = self.nano + nanosToAdd
		let remainder = nanosTotal % NANOS_PER_SECOND
		let carry = nanosTotal / NANOS_PER_SECOND - (remainder < 0 ? 1 : 0)

		return .clock(
			self.seconds + secondsToAdd + carry,
			remainder < 0 ? remainder + NANOS_PER_SECOND : remainder,
		)
	}

}


extension ClockTime : Hashable {}


extension ClockTime : Codable {

	/// ValueContainerにはDouble値単体で格納する
	public init(
		from decoder: any Decoder,
	) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(Double.self)

		guard let clock = Self.normalized(seconds: value)
		else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "ClockTime seconds must be finite and within the supported range",
			)
		}

		self = clock
	}
	
	/// ValueContainerにはDouble値単体で格納されている
	public func encode(
		to encoder: any Encoder,
	) throws {
		var container = encoder.singleValueContainer()
		try container.encode(asDouble)
	}
	
}


extension ClockTime {
	
	/// システムタイムゾーンのClockTimeのLocalDateTime表現
	@inlinable
	public var asLocalDateTime: LocalDateTime {
		.dateTime(self, zone: .system)
	}

	/// 指定タイムゾーンのClockTimeのLocalDateTime表現
	@inlinable
	public func asLocalDateTime(
		zone: TimeZone,
	) -> LocalDateTime {
		.dateTime(self, zone: zone)
	}

	/// 指定タイムゾーンのZonedDateTime表現
	@inlinable
	public func asZonedDateTime(
		zone: TimeZone = .utc,
	) -> ZonedDateTime {
		.init(dateTime: asLocalDateTime(zone: zone), zone: zone)
	}

	/// POSIX形式でフォーマットした文字列
	@inlinable
	public func format(
		posix format: String,
	) -> String? {
		POSIX.strftime(
			self,
			format: format,
		)
	}

}


extension ClockTime : CustomStringConvertible {
	
	public var description: String {
		asDouble.description
	}
	
}
