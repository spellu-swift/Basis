

// MARK: (Orderable, Orderable) -> Ordering


/// 値の比較
@inlinable
public func compare<Value>(
	_ lhs: Value,
	_ rhs: Value
) -> Ordering where Value : Orderable {
	lhs <=> rhs
}


/// 要素の比較
@inlinable
public func compare<V, W>(
	_ lhs: V,
	_ rhs: V,
	_ keyPath: KeyPath<V, W>
) -> Ordering where W : Orderable {
	lhs[keyPath: keyPath]
	<=>
	rhs[keyPath: keyPath]
}


///// オプショナル要素の比較
//@inlinable
//public func compare<V, W>(
//	_ lhs: V,
//	_ rhs: V,
//	_ keyPath: KeyPath<V, Optional<W>>
//) -> Ordering where W : Orderable {
//	lhs[keyPath: keyPath]
//	<=>
//	rhs[keyPath: keyPath]
//}


/// 要素のカスタマイズ比較
@inlinable
public func compare<V, W, X>(
	_ lhs: V,
	_ rhs: V,
	_ keyPath: KeyPath<V, W>,
	_ compute: ((W) -> X)
) -> Ordering where X : Orderable {
	compute(lhs[keyPath: keyPath])
	<=>
	compute(rhs[keyPath: keyPath])
}


@inlinable
public func compare<V, W, X>(
	_ lhs: V,
	_ rhs: V,
	_ keyPath: KeyPath<V, W>,
	_ compare: ((X, X) -> Ordering)
) -> Ordering where W : Collection, W.Element == X {
	for (l, r) in zip(lhs[keyPath: keyPath], rhs[keyPath: keyPath]) {
		let result = compare(l, r)
		
		if result != .equal {
			return result
		}
	}
	
	return .equal
}
