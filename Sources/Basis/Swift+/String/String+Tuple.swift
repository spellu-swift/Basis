

extension String {


	public init<Tuple>(
		tuple: Tuple
	) {
		self = withUnsafeBytes(of: tuple) {
			String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self))
		}
	}
	
	
}
