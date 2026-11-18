

extension Range : Orderable where Bound : Orderable {
	
	public static func <=> (
		lhs: Self,
		rhs: Self,
	) -> Basis.Ordering {
		Basis
			.compare(lhs, rhs, \.lowerBound)
			.compare(lhs, rhs, \.upperBound)
	}
	
}


extension RangeSet : Orderable where Bound : Orderable {
	
	public static func <=>(
		_ lhs: Self,
		_ rhs: Self,
	) -> Ordering {
		// compare sequence
		Basis
			.compare(lhs, rhs, \.ranges) { $0.map{$0} }
	}
	
}


extension RangeSet {
	
	public var count: Int {
		ranges.count
	}
	
}


extension RangeSet where Bound : Strideable, Bound.Stride : SignedInteger {
	
	@inlinable
	public var iterator: some Sequence<Bound> {
		ranges.map{$0.makeIterator()}.joined()
	}
	
}



