

infix operator <=> : ComparisonPrecedence


@attached(
	extension,
	names: named(<=>), named(==), named(<), named(<=), named(>=), named(>),
	conformances: Orderable & Equatable & Comparable
)
public macro Orderable()
= #externalMacro(module: "BasisMacros", type: "OrderableMacro")


public protocol Orderable {
	
	static func <=>(
		lhs: Self,
		rhs: Self,
	) -> Ordering
	
}


// MARK: Optional + Ordeable


extension Swift.Optional : Orderable where Wrapped : Orderable {
	
	@inlinable
	public static func <=>(
		_ lhs: Self,
		_ rhs: Self,
	) -> Ordering {
		switch (lhs, rhs) {
			case let (.some(l), .some(r)): l <=> r
			case (.some, .none):           .greater
			case (.none, .some):           .less
			case (.none, .none):           .equal
		}
	}
	
}


// MARK: Bool + Ordeable


extension Swift.Bool : Orderable {
	
	@inlinable
	public static func <=>(
		_ lhs: Self,
		_ rhs: Self,
	) -> Ordering {
		switch (lhs, rhs) {
			case (true,  true ): .equal
			case (true,  false): .greater
			case (false, true ): .less
			case (false, false): .equal
		}
	}
	
}


// MARK: Comparable + Ordeable


extension Comparable where Self : Orderable {
	
	@inlinable
	public static func <=>(
		_ lhs: Self,
		_ rhs: Self,
	) -> Ordering {
		if lhs == rhs {
			.equal
		}
		else if lhs < rhs {
			.less
		}
		else {
			.greater
		}
	}
	
}


extension Int : Orderable {}

extension Int8 : Orderable {}

extension Int16 : Orderable {}

extension Int32 : Orderable {}

extension Int64 : Orderable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
extension Int128 : Orderable {}

extension UInt : Orderable {}

extension UInt8 : Orderable {}

extension UInt16 : Orderable {}

extension UInt32 : Orderable {}

extension UInt64 : Orderable {}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
extension UInt128 : Orderable {}

extension String : Orderable {}

extension Array : Orderable where Element : Orderable {}

extension Collection where Element : Orderable {
	
	public static func <=> (
		lhs: Self,
		rhs: Self,
	) -> Ordering {
		for (l, r) in zip(lhs, rhs) {
			let result: Ordering = (l <=> r)
			
			if result.isNotEqual {
				return result
			}
		}
		
		return lhs.count <=> rhs.count
	}
	
}

//extension Dictionary : Orderable where Key : Orderable, Value : Orderable {}

extension OrderedDictionary : Orderable where Key : Orderable, Value : Orderable {
	
	public static func <=> (
		lhs: OrderedDictionary<Key, Value>,
		rhs: OrderedDictionary<Key, Value>,
	) -> Ordering {
		Basis
			.compare(lhs, rhs, \.elements) { l, r in
				Basis
					.compare(l, r, \.0)
					.compare(l, r, \.1)
			}
	}
	
}

