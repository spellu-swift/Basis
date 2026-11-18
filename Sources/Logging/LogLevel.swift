import Basis


///
/// ログレベル
///
/// SEE: https://logging.apache.org/log4j/2.x/manual/customloglevels.html
///
public enum LogLevel : String, Sendable, Hashable, Codable {
	
	case off      = "OFF"
	case critical = "CRITICAL"
	case error    = "ERROR"
	case warning  = "WARNING"
	case info     = "INFO"
	case debug    = "DEBUG"
	case trace    = "TRACE"
	case all      = "ALL"
	
}


extension LogLevel : Orderable, Comparable {

	public static func <=> (
		lhs: LogLevel,
		rhs: LogLevel,
	) -> Basis.Ordering {
		compare(lhs, rhs, \.priority)
	}
	
	public static func < (
		lhs: LogLevel,
		rhs: LogLevel,
	) -> Bool {
		lhs.priority < rhs.priority
	}
	
	public var priority: Int {
		switch self {
			case .off:
				0
			case .critical:
				100
			case .error:
				200
			case .warning:
				300
			case .info:
				400
			case .debug:
				500
			case .trace:
				600
			case .all:
				Int.max
		}
	}
	
}


extension LogLevel : CustomStringConvertible {
	
	public var description: String {
		rawValue
	}
	
}
