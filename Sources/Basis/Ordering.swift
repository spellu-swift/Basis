

/// 2つの要素に順序
@frozen
public enum Ordering : Int, Sendable {

	case less     = -1  // A < B
	case equal    = 0   // A == B
	case greater  = 1   // A > B

}


extension Ordering {

	@inlinable public var isLess: Bool {
		self == .less
	}
	
	@inlinable public var isEqual: Bool {
		self == .equal
	}
	
	@inlinable public var isNotEqual: Bool {
		self != .equal
	}
	
	@inlinable public var isGreater: Bool {
		self == .greater
	}
	
	@inlinable public var isLessThan: Bool {
		self != .greater
	}
	
	@inlinable public var isGreaterThan: Bool {
		self != .less
	}

}


extension Ordering {

	/// 要素の比較
	@inlinable
	public func compare<V>(
		_ lhs: V,
		_ rhs: V
	) -> Ordering where V : Orderable {
		self == .equal ? lhs <=> rhs : self
	}
	
	/// 要素の比較
	@inlinable
	public func compare<V, W>(
		_ lhs: V,
		_ rhs: V,
		_ keyPath: KeyPath<V, W>
	) -> Ordering where W : Orderable {
		if self == .equal {
			lhs[keyPath: keyPath]
			<=>
			rhs[keyPath: keyPath]
		} else {
			self
		}
	}
	
	/// 要素のカスタマイズ比較
	@inlinable
	public func compare<V, W, X>(
		_ lhs: V,
		_ rhs: V,
		_ keyPath: KeyPath<V, W>,
		_ compute: ((W) -> X)
	) -> Ordering where X : Orderable {
		if self == .equal {
			compute(lhs[keyPath: keyPath])
			<=>
			compute(rhs[keyPath: keyPath])
		} else {
			self
		}
	}

	@inlinable
	public func compare<V, W, X>(
		_ lhs: V,
		_ rhs: V,
		_ keyPath: KeyPath<V, W>,
		_ compare: ((X, X) -> Ordering)
	) -> Ordering where W : Collection, W.Element == X {
		if self == .equal {
			Basis.compare(lhs, rhs, keyPath, compare)
		} else {
			self
		}
	}
	
	public func `else`(
		_ compare: () -> Self
	) -> Self {
		self == .equal ? compare() : self
	}

}

