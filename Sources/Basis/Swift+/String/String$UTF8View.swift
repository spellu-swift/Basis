

extension String.UTF8View {
	
	@inlinable
	public var asArray: [UInt8] {
		.init(self)
	}

	@inlinable
	public var asArraySlice: ArraySlice<UInt8> {
		.init(self)
	}
	

	@inlinable
	public subscript (
		_ range: Range<Int>,
	) -> Substring.UTF8View {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
	@inlinable
	public subscript (
		_ range: ClosedRange<Int>,
	) -> Substring.UTF8View {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			...
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
}


extension String.UTF16View {
	
	@inlinable
	public var asArray: [UInt16] {
		.init(self)
	}

	@inlinable
	public var asArraySlice: ArraySlice<UInt16> {
		.init(self)
	}

	@inlinable
	public subscript (
		_ range: Range<Int>,
	) -> Substring.UTF16View {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
	@inlinable
	public subscript (
		_ range: ClosedRange<Int>,
	) -> Substring.UTF16View {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			...
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
}


extension String.UnicodeScalarView {
	
	@inlinable
	public var asArray: [UnicodeScalar] {
		.init(self)
	}

	@inlinable
	public var asArraySlice: ArraySlice<UnicodeScalar> {
		.init(self)
	}
	
	@inlinable
	public subscript (
		_ range: Range<Int>,
	) -> Substring.UnicodeScalarView {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
	@inlinable
	public subscript (
		_ range: ClosedRange<Int>,
	) -> Substring.UnicodeScalarView {
		self[
			index(startIndex, offsetBy: range.lowerBound)
			...
			index(startIndex, offsetBy: range.upperBound)
		]
	}
	
}

