import MacroTesting
import BasisMacros


private struct Tests {

	@Test func orderableMacro_conformance_Hashable() {
		expect(
			macros: [
				"Orderable": OrderableMacro.self,
			],
			indentationWidth: .tab
		) {
"""
@Orderable
struct Foo : Hashable, Sendable {
}
"""
		} expansion: {
"""
struct Foo : Hashable, Sendable {
}

extension Foo : Orderable & Comparable {
\tpublic static func <=>(
\t\tlhs: Self,
\t\trhs: Self
\t) -> Basis.Ordering {
\t\t.equal

\t}

\t@inlinable
\tpublic static func ==(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isEqual
\t}

\t@inlinable
\tpublic static func <(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLess
\t}

\t@inlinable
\tpublic static func <=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLessThan
\t}

\t@inlinable
\tpublic static func >=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreaterThan
\t}

\t@inlinable
\tpublic static func >(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreater
\t}
}
"""
		}
	}
	
	@Test func orderableMacro_struct() {
		expect(
			macros: [
				"Orderable": OrderableMacro.self,
			],
			indentationWidth: .tab
		) {
"""
@Orderable
struct Foo {
 var a: Int
 var b: Int {2}
}
"""
		} expansion: {
"""
struct Foo {
 var a: Int
 var b: Int {2}
}

extension Foo : Orderable & Comparable & Equatable {
\tpublic static func <=>(
\t\tlhs: Self,
\t\trhs: Self
\t) -> Basis.Ordering {
\t\t.equal
\t\t\t.compare(lhs, rhs, \\.a)
\t}

\t@inlinable
\tpublic static func ==(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isEqual
\t}

\t@inlinable
\tpublic static func <(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLess
\t}

\t@inlinable
\tpublic static func <=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLessThan
\t}

\t@inlinable
\tpublic static func >=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreaterThan
\t}

\t@inlinable
\tpublic static func >(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreater
\t}
}
"""
		}
	}
	
	
	@Test func orderableMacro_withGenericParameter() {
		expect(
			macros: [
				"Orderable": OrderableMacro.self,
			],
			indentationWidth: .tab
		) {
"""
@Orderable
struct Foo<A> {
 var a: Int
 var b: Int {2}
}
"""
		} expansion: {
"""
struct Foo<A> {
 var a: Int
 var b: Int {2}
}

extension Foo : Orderable & Comparable & Equatable where A : Orderable {
\tpublic static func <=>(
\t\tlhs: Self,
\t\trhs: Self
\t) -> Basis.Ordering {
\t\t.equal
\t\t\t.compare(lhs, rhs, \\.a)
\t}

\t@inlinable
\tpublic static func ==(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isEqual
\t}

\t@inlinable
\tpublic static func <(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLess
\t}

\t@inlinable
\tpublic static func <=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLessThan
\t}

\t@inlinable
\tpublic static func >=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreaterThan
\t}

\t@inlinable
\tpublic static func >(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreater
\t}
}
"""
		}
	}
	
}
