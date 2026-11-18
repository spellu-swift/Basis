import Basis


/// 異なる型の2個以上の要素を格納するタプル。
///
/// 最初の2個の型引数は必須で、残りは省略できる。
public typealias Tuple<First, Second, each Rest>
= _Tuple<First, Second, repeat each Rest>


/// Tupleの格納・比較・ハッシュを実装する型。通常はTupleを使用する。
///
/// 固定要素とパックが混在するタプルはeachで反復できないため、
/// 実装では全要素をひとつのパックとして扱い、公開する型別名で個数を制限する。
/// Apple Swift 6.4では、混在タプルをパック用の比較ヘルパーへ渡す方法も
/// コード生成時にコンパイラがクラッシュするため、この構成としている。
public struct _Tuple<each N> {

	public typealias Value = (repeat each N)

	/// 格納されたタプル。
	///
	/// Apple Swift 6.4（swiftlang-6.4.0.34.1）では、
	/// `tuple.value.1.append("c")`のように要素を直接inoutで扱うと、
	/// コード生成時にコンパイラがクラッシュすることを確認している。
	/// `#expect(tuple.value.0 == 1)`でも同様の問題があるため、
	/// 検証時には`let (first, second) = tuple.value`のように先に分解する。
	/// 更新時には、次のようにタプルを取り出して変更してから再代入する。
	///
	/// ```swift
	/// var tuple: Tuple<Int, String> = .init(value: (1, "a"))
	/// var value: Tuple<Int, String>.Value = tuple.value
	/// value.1.append("c")
	/// tuple.value = value
	/// ```
	public var value: Value
	
	public init(
		value: Value,
	) {
		self.value = value
	}

	/// 要素を個別に指定して初期化する。
	public init(
		_ elements: repeat each N,
	) {
		self.value = (repeat each elements)
	}

}
extension _Tuple : Sendable where repeat each N : Sendable {}
extension _Tuple : Equatable where repeat each N : Equatable {

	public static func == (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		for (l, r) in repeat (each lhs.value, each rhs.value) {
			if l != r {
				return false
			}
		}
		return true
	}

}
extension _Tuple : Hashable where repeat each N : Hashable {

	public func hash(
		into hasher: inout Hasher,
	) {
		for element in repeat each value {
			hasher.combine(element)
		}
	}

}
extension _Tuple : Comparable where repeat each N : Comparable {

	/// 最初に異なる要素の大小で辞書式に比較する。
	public static func < (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		for (l, r) in repeat (each lhs.value, each rhs.value) {
			if l != r {
				return l < r
			}
		}
		return false
	}

}
extension _Tuple : Orderable where repeat each N : Orderable {

	/// 最初に等しくない要素のOrderingを返す。
	public static func <=> (
		lhs: Self,
		rhs: Self,
	) -> Ordering {
		for (l, r) in repeat (each lhs.value, each rhs.value) {
			let result: Ordering = l <=> r
			if result.isNotEqual {
				return result
			}
		}
		return .equal
	}

}


public protocol TupleProtocol {

	associatedtype Value

	var value: Value { get }

}
extension _Tuple: TupleProtocol {}
extension _Tuple : CustomDebugStringConvertible {

	public var debugDescription: String {
		"\(value)"
	}

}


extension Sequence where Element : TupleProtocol {

	public var values: [Element.Value] {
		map(\.value)
	}

}


// MARK: 要素2個の固定タプル


public struct Pair<_0, _1> : TupleProtocol {

	public typealias Value = (_0, _1)
	public var _0: _0
	public var _1: _1
		
	public init(
		_ _0: _0,
		_ _1: _1
	) {
		self._0 = _0
		self._1 = _1
	}

	@inlinable
	public var value: Value {
		get {
			(self._0, self._1)
		}
		set {
			(self._0, self._1) = newValue
		}
	}

}


extension Pair : Orderable where _0 : Orderable, _1 : Orderable {

	public static func <=> (
		lhs: Self,
		rhs: Self,
	) -> Ordering {
		.equal
		.compare(lhs, rhs, \._0)
		.compare(lhs, rhs, \._1)
	}
	
	@inlinable
	public static func == (lhs: Self, rhs: Self) -> Bool {
		(lhs <=> rhs).isEqual
	}
	
	@inlinable
	public static func < (lhs: Self, rhs: Self) -> Bool {
		(lhs <=> rhs).isLess
	}
	
	@inlinable
	public static func <= (lhs: Self, rhs: Self) -> Bool {
		(lhs <=> rhs).isLessThan
	}
	
	@inlinable
	public static func >= (lhs: Self, rhs: Self) -> Bool {
		(lhs <=> rhs).isGreaterThan
	}
	
	@inlinable
	public static func > (lhs: Self, rhs: Self) -> Bool {
		(lhs <=> rhs).isGreater
	}

}

extension Pair : Sendable where _0 : Sendable, _1 : Sendable {}

extension Pair : Equatable where _0 : Equatable, _1 : Equatable {}

//extension Pair : Comparable where _0 : Comparable, _1 : Comparable {}

extension Pair : Hashable where _0 : Hashable, _1 : Hashable {}

extension Pair : CustomDebugStringConvertible {
	public var debugDescription: String {
		"\(value)"
	}
}


extension Collection {

	public func forEach<_0, _1>(
		_ body: (_0, _1) throws -> Void,
	) rethrows where Element == Pair<_0, _1> {
		try self.forEach {
			try body($0._0, $0._1)
		}
	}
	
	public func filter<_0, _1>(
		_ isIncluded: (_0, _1) throws -> Bool,
	) rethrows -> [Element] where Element == Pair<_0, _1> {
		try self.filter {
			try isIncluded($0._0, $0._1)
		}
	}
	
	public func map<T, _0, _1>(
		_ transform: (_0, _1) throws -> T,
	) rethrows -> [T] where Element == Pair<_0, _1> {
		try self.map {
			try transform($0._0, $0._1)
		}
	}
	
	public func compactMap<T, _0, _1>(
		_ transform: (_0, _1) throws -> T?,
	) rethrows -> [T] where Element == Pair<_0, _1> {
		try self.compactMap {
			try transform($0._0, $0._1)
		}
	}
	
}


extension Array {
	
	@inlinable
	@discardableResult
	public mutating func push<_0, _1>(
		_ t: (_0, _1),
	) -> (_0, _1) where Element == Pair<_0, _1> {
		self.append(.init(t.0, t.1))
		return t
	}
	
	@inlinable
	public mutating func pop<_0, _1>(
	) -> (_0, _1)? where Element == Pair<_0, _1> {
		self.pop()?.value
	}
	
	@inlinable
	public mutating func append<_0, _1>(
		_ t: (_0, _1),
	) where Element == Pair<_0, _1> {
		self.append(.init(t.0, t.1))
	}
	
	public mutating func modifyAll<_0, _1>(
		_ transform: (inout (_0, _1)) throws -> Void,
	) rethrows where Element == Pair<_0, _1> {
		try self.modifyAll {
			var value: (_0, _1) = $1.value
			try transform(&value)
			$1.value = value
		}
	}
	
	public mutating func modifyAll<_0, _1>(
		_ transform: (Index, inout (_0, _1)) throws -> Void,
	) rethrows where Element == Pair<_0, _1> {
		try self.modifyAll {
			var value: (_0, _1) = $1.value
			try transform($0, &value)
			$1.value = value
		}
	}
	
}


extension Dictionary {
	
	public subscript<_0, _1>(
		_ key: (_0, _1),
	) -> Value? where Key == Pair<_0, _1> {
		get {
			self[.init(key.0, key.1)]
		}
		set {
			self[.init(key.0, key.1)] = newValue
		}
	}
	
	public func filter<_0, _1>(
		_ isIncluded: (Key, (_0, _1)) throws -> Bool,
	) rethrows -> [Key : Value] where Value == Pair<_0, _1> {
		try self.filter {
			try isIncluded($0, ($1._0, $1._1))
		}
	}
	
	public func map<T, _0, _1>(
		_ transform: (_ key: Key, _ value: (_0, _1)) throws -> T,
	) rethrows -> [T] where Value == Pair<_0, _1> {
		try self.map {
			try transform($0, ($1._0, $1._1))
		}
	}
	
	public func mapValues<T, _0, _1>(
		_ transform: (_ value: (_0, _1)) throws -> T,
	) rethrows -> [Key : T] where Value == Pair<_0, _1> {
		try self.mapValues {
			try transform($0.value)
		}
	}
	
	public func compactMapValues<T, _0, _1>(
		_ transform: (_ value: (_0, _1)) throws -> T?,
	) rethrows -> [Key : T] where Value == Pair<_0, _1> {
		try self.compactMapValues {
			try transform($0.value)
		}
	}
	
	public mutating func modifyAll<_0, _1>(
		_ transform: (Key, inout (_0, _1)) throws -> Void,
	) rethrows where Value == Pair<_0, _1> {
		try self.modifyAll {
			var value = $1.value
			try transform($0, &value)
			$1.value = value
		}
	}
	
}


extension OrderedDictionary {
	
	public subscript<_0, _1>(
		_ key: (_0, _1),
	) -> Value? where Key == Pair<_0, _1> {
		get {
			self[.init(key.0, key.1)]
		}
		set {
			self[.init(key.0, key.1)] = newValue
		}
	}
	
	public func map<T, _0, _1>(
		_ transform: (_ key: Key, _ value: (_0, _1)) throws -> T,
	) rethrows -> [T] where Value == Pair<_0, _1> {
		try self.map {
			try transform($0, ($1._0, $1._1))
		}
	}
	
	public mutating func modifyAll<_0, _1>(
		_ transform: (Key, inout (_0, _1)) throws -> Void,
	) rethrows where Value == Pair<_0, _1> {
		try self.modifyAll {
			var value = $1.value
			try transform($0, &value)
			$1.value = value
		}
	}
	
//	public func mapValues<T, _0, _1>(
//		_ transform: (_ value: (_0, _1)) throws -> T,
//	) rethrows -> [Key : T] where Value == Pair<_0, _1> {
//		try self.mapValues {
//			try transform(($0._0, $0._1))
//		}
//	}
	
}
