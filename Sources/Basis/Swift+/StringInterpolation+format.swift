

public extension String.StringInterpolation {
	
	mutating func appendInterpolation(
		_ value: CVarArg,
		format: String,
	) {
		appendLiteral(
			POSIX.format(format, value)
		)
	}
	
}
