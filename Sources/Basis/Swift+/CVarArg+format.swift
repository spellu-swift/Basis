
extension CVarArg {
	
	@inlinable
	public func format(
		_ format: String,
	) -> String {
		POSIX.format(format, self)
	}
	
}
