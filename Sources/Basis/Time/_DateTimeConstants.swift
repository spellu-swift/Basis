

/// 400年周期における日数
public let DAYS_PER_CYCLE: Int = 146097


/// 0年から1970年までの日数。
/// 0年から2000年までの間に、400年周期が5回ある。
/// 1970年から2000年までの間に、閏年が7回ある。
public let DAYS_0000_TO_1970: Int = (DAYS_PER_CYCLE * 5) - (30 * 365 + 7)


public let HOURS_PER_DAY: Int = 24

public let MINUTES_PER_HOUR: Int = 60

public let SECONDS_PER_MINUTE: Int = 60
public let SECONDS_PER_HOUR: Int = MINUTES_PER_HOUR * SECONDS_PER_MINUTE
public let SECONDS_PER_DAY = HOURS_PER_DAY * SECONDS_PER_HOUR

public let NANOS_PER_SECOND: Int = 1_000_000_000
public let NANOS_PER_MINUTE: Int = SECONDS_PER_MINUTE * NANOS_PER_SECOND
public let NANOS_PER_HOUR: Int = SECONDS_PER_HOUR * NANOS_PER_SECOND


