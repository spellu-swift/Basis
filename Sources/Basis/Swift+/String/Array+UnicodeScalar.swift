

extension [UnicodeScalar] {
	
//	@inlinable
//	public var asString: String {
//		String(String.UnicodeScalarView(self))
//	}
	
	@inlinable
	public func index<S : StringProtocol> (
		_ offset: Int,
		of string: S,
	) -> String.Index {
		.init(utf16Offset: offset, in: string)
	}

}
