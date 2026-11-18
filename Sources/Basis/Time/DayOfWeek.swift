

//@Orderable
public enum DayOfWeek : Int {
	
	case sunday = 1
	case monday = 2
	case tuesday = 3
	case wednesday = 4
	case thursday = 5
	case friday = 6
	case saturday = 7

}


extension DayOfWeek : Orderable & Comparable & Equatable {

	public static func <=> (
		lhs: Self,
		rhs: Self,
	) -> Basis.Ordering {
		Basis
			.compare(lhs, rhs, \.rawValue)
	}

	@inlinable
	public static func < (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

}


extension DayOfWeek : Hashable {}


extension DayOfWeek : Codable {}


