

public enum CalendarArithmeticError : ProgramError, Sendable {

	case invalidDate(LocalDate)
	case invalidTime(LocalTime)
	case outOfRange
	case integerOverflow

}


enum CalendarArithmetic {

	static let nanosPerDay = SECONDS_PER_DAY * NANOS_PER_SECOND

	static func add(_ lhs: Int, _ rhs: Int, subtract: Bool = false) throws -> Int {
		let result: (partialValue: Int, overflow: Bool)
		= subtract ? lhs.subtractingReportingOverflow(rhs) : lhs.addingReportingOverflow(rhs)

		guard
			!result.overflow
		else { throw CalendarArithmeticError.integerOverflow }

		return result.partialValue
	}

	static func floorDivide(_ value: Int, by divisor: Int) -> Int {
		value / divisor - (value % divisor < 0 ? 1 : 0)
	}

}
