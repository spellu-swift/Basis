

///
/// 時間間隔表現
///
public enum TimeIntervalRepresentation : Sendable, Hashable {
	
	case seconds(Double)

	case nanoseconds(UInt64)
	
}


extension TimeIntervalRepresentation {

	/// 秒(Double値)に変換する
	public var asSeconds: Double {
		switch self {
			case .seconds(let seconds):
				seconds
			case .nanoseconds(let nanoseconds):
				Double(nanoseconds) / 1_000_000_000 // NSEC_PER_SEC == 1_000_000_000
		}
	}

	/// ナノ秒(UInt64値)に変換する
	public var asNanoSeconds: UInt64 {
		switch self {
			case .seconds(let seconds):
				UInt64(seconds * 1_000_000_000) // NSEC_PER_SEC == 1_000_000_000
			case .nanoseconds(let nanoseconds):
				nanoseconds
		}
	}
	
}
