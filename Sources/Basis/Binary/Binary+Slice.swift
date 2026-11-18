

extension Slice : @retroactive Equatable where Base == Binary {}


extension Slice where Base == Binary {
	
	
	@inlinable
	public var asBinary: Binary {
		Binary(asBytes)
	}
	
	
	@inlinable
	public var asBytes: [UInt8] {
		.init(asArraySlice)
	}
	
	
	@inlinable
	public var asArraySlice: ArraySlice<Base.Element> {
		base._raw[range]
	}


}


extension Slice where Base == Binary {


	@inlinable
	public static func == (
		lhs: Self,
		rhs: Self
	) -> Bool {
		guard lhs.count == rhs.count
		else { return false }
		
		if lhs.base == rhs.base && lhs.range == rhs.range {
			return true
		}
		else {
			return lhs.asArraySlice == rhs.asArraySlice
		}
	}
	

	@inlinable
	public static func == (
		lhs: Self,
		rhs: ArraySlice<UInt8>
	) -> Bool {
		lhs.asArraySlice == rhs
	}
	
	
}


@inlinable
public func == (
	lhs: Slice<Binary>?,
	rhs: [UInt8]
) -> Bool {
	lhs?.asArraySlice == rhs[...]
}
