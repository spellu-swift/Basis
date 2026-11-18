

public protocol TreeExpression : Equatable {}


///
/// ツリー構造を持つタプル
///
/// Variadic Generic Typeを使用して実装している。
///
public struct TreeTuple<each T> {

	public init(
		_ value: (repeat each T),
		_ children: [TreeTuple<repeat each T>] = [],
	) {
		self.value = value
		self.children = children
	}

	public init(
		_ value: repeat each T,
		children: [TreeTuple<repeat each T>] = [],
	) {
		self.value = (repeat each value)
		self.children = children
	}

	public init(
		_ value: repeat each T,
		children: () -> [TreeTuple<repeat each T>],
	) {
		self.value = (repeat each value)
		self.children = children()
	}

	public let value: (repeat each T)

	public let children: [TreeTuple<repeat each T>]

}
extension TreeTuple : TreeExpression & Equatable where repeat each T : Equatable {
	
	public static func == (
		_ lhs: Self,
		_ rhs: Self,
	) -> Bool {
		for (l, r) in repeat (each lhs.value, each rhs.value) {
			guard l == r else {
				return false
			}
		}

		return lhs.children == rhs.children
	}
	
}
extension TreeTuple : CustomDebugStringConvertible {
	
	public var debugDescription: String {
		asTreeString()
	}
	
	func asTreeString(
		indent: String = "",
	) -> String {
		(
			["\(indent)\(value)"]
			+
			children.map {
				$0.asTreeString(
					indent: indent + "\t"
				)
			}
		)
		.joined(separator: "\n")
	}

}
extension Sequence {

	///
	/// TupleTreeへの変換
	///
	public func map<each T>(
		_ keyPaths: repeat KeyPath<Element, each T>,
		children: KeyPath<Element, [Element]>,
	) -> [TreeTuple<repeat each T>] {
		map { element in
			TreeTuple(
				(repeat element[keyPath: each keyPaths]),
				element[keyPath: children].map(
					repeat each keyPaths,
					children: children,
				)
			)
		}
	}

}


///
/// TupleTreeをビルドする
///
public func Tree<each T>(
	_ value: repeat each T,
	@TreeTupleBuilder children: () -> [TreeTuple<repeat each T>] = {[]},
) -> TreeTuple<repeat each T> {
	TreeTuple(
		(repeat each value),
		children(),
	)
}


///
/// TreeTupleのResultBuilder
///
@resultBuilder
public enum TreeTupleBuilder {

	public static func buildBlock<each T>(
		_ components: TreeTuple<repeat each T>...
	) -> [TreeTuple<repeat each T>] {
		components
	}

	public static func buildBlock<each T>(
		_ components: [TreeTuple<repeat each T>]
	) -> [TreeTuple<repeat each T>] {
		components
	}

}
