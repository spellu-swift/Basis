

///
/// タプルの比較
///
public func == <each Element: Equatable>(
	_ lhs: (repeat each Element),
	_ rhs: (repeat each Element),
) -> Bool {
	for (l, r) in repeat (each lhs, each rhs) {
		guard l == r else {
			return false
		}
	}
	
	return true
}


///
/// Optionalタプルの比較
///
public func == <each Element: Equatable>(
	_ lhs: (repeat each Element)?,
	_ rhs: (repeat each Element)?,
) -> Bool {
#if false
	switch (lhs, rhs) {
	case (nil, nil):
		return true

	case let (.some(lhs), .some(rhs)):
		for (l, r) in repeat (each lhs, each rhs) {
			guard l == r else {
				return false
			}
		}

		return true

	default:
		return false
	}
#else
	guard let lhs else {
		if case nil = rhs {
			return true
		}
		return false
	}

	guard let rhs else {
		return false
	}

	for (l, r) in repeat (each lhs, each rhs) {
		guard l == r else {
			return false
		}
	}

	return true
#endif
}


///
/// タプル配列の比較
///
public func == <each Element: Equatable>(
	_ lhs: [(repeat each Element)],
	_ rhs: [(repeat each Element)],
) -> Bool {
	lhs.elementsEqual(rhs) { left, right in
		for (l, r) in repeat (each left, each right) {
			guard l == r else {
				return false
			}
		}
		return true
	}
}


///
/// Optionalタプルの比較
///
@inlinable
public func != <each Element: Equatable>(
	_ lhs: (repeat each Element),
	_ rhs: (repeat each Element),
) -> Bool {
	for (l, r) in repeat (each lhs, each rhs) {
		if l != r {
			return true
		}
	}

	return false
}


///
/// Optionalタプルの比較
///
@inlinable
public func != <each Element: Equatable>(
	_ lhs: (repeat each Element)?,
	_ rhs: (repeat each Element)?,
) -> Bool {
	guard let lhs else {
		if case nil = rhs {
			return false
		}
		return true
	}

	guard let rhs else {
		return true
	}

	for (l, r) in repeat (each lhs, each rhs) {
		if l != r {
			return true
		}
	}

	return false
}


///
/// タプル配列の比較
///
//@inlinable
public func != <each Element: Equatable>(
	_ lhs: [(repeat each Element)],
	_ rhs: [(repeat each Element)],
) -> Bool {
	lhs.elementsEqual(rhs) { left, right in
		for (l, r) in repeat (each left, each right) {
			guard l != r else {
				return false
			}
		}
		return true
	}
}


