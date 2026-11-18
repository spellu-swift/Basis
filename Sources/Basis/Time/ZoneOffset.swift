

///
/// ゾーンオフセット
/// UTCからの相対秒数を表します。
///
@Orderable
public struct ZoneOffset : Sendable {
	
	public let totalSeconds: Int
	
	public let id: String
	
}


extension ZoneOffset {

	/// Constant for the maximum supported offset.
	public static let MAX: ZoneOffset
	= .ofTotalSeconds(MAX_SECONDS)
	
	/// The time-zone offset for UTC, with an ID of 'Z'.
	public static let UTC: ZoneOffset
	= .ofTotalSeconds(0)
	
	/// Constant for the minimum supported offset.
	public static let MIN: ZoneOffset
	= .ofTotalSeconds(-MAX_SECONDS)
	
	/// The abs maximum seconds.
	private static let MAX_SECONDS: Int
	= 18 * SECONDS_PER_HOUR
	
}


extension ZoneOffset {
	
	/// 相対秒数からゾーンオフセットを生成する
	public static func ofTotalSeconds(
		_ totalSeconds: Int,
	) -> Self {
		guard
			-MAX_SECONDS <= totalSeconds && totalSeconds <= +MAX_SECONDS
		else { fatalError("Zone offset not in valid range: -18:00 to +18:00") }
		
		return Self(
			totalSeconds: totalSeconds,
			id: buildId(totalSeconds, ext: false),
		)
	}
	
}


extension ZoneOffset : Hashable {}


extension ZoneOffset : Codable {}


extension ZoneOffset : CustomStringConvertible {
		
	public var description: String {
		buildId(totalSeconds, ext: true)
	}
		
}


private func buildId(
	_ totalSeconds: Int,
	ext: Bool,
) -> String {
	if totalSeconds == 0 {
		return "Z";
	}
	
	let absTotalSeconds: Int = abs(totalSeconds)
	let absHours: Int = absTotalSeconds / SECONDS_PER_HOUR
	let absMinutes: Int = (absTotalSeconds / SECONDS_PER_MINUTE) % MINUTES_PER_HOUR
	let absSeconds: Int = absTotalSeconds % SECONDS_PER_MINUTE
	
	var buffer: String = totalSeconds < 0 ? "-" : "+"
	
	buffer += (absHours < 10 ? "0\(absHours)" : "\(absHours)")
	
	if ext {
		buffer += ":"
	}
	
	buffer += (absMinutes < 10 ? "0\(absMinutes)" : "\(absMinutes)")
	
	if absSeconds != 0 {
		if ext {
			buffer += ":"
		}
		
		buffer += (absSeconds < 10 ? "0\(absSeconds)" : "\(absSeconds)")
	}
	
	return buffer
}


