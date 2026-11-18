import MacroTesting
import BasisMacros


@Test func defaultMacro_struct() {
	expect(
		macros: [
			"Default": DefaultMacro.self,
		],
	) {
"""
@Default
struct Foo {}
"""
	} expansion: {
"""
struct Foo {}

extension Foo : Default {
\tstatic let `default`: Foo = .init()
}
"""
	}
	
}



@Test func defaultMacro_public_struct() {
	expect(
		macros: [
			"Default": DefaultMacro.self,
		],
	) {
"""
@Default
public struct Foo {}
"""
	} expansion: {
"""
public struct Foo {}

extension Foo : Default {
\tpublic static var `default`: Foo {
\t\t.init()
\t}
}
"""
	}
	
}




@Test func defaultMacro_withMember() {
	expect(
		macros: [
			"Default": DefaultMacro.self,
		],
	) {
"""
@Default
struct Foo {
	var a: Int
	var b: Bool?
	var c: [String]
	var d: Bar
}
"""
	} expansion: {
"""
struct Foo {
	var a: Int
	var b: Bool?
	var c: [String]
	var d: Bar
}

extension Foo : Default {
\tstatic let `default`: Foo = .init(a: 0, b: nil, c: [], d: .default)
}
"""
	}
	
}


@Test func defaultMacro_withMember_andDefaultValue() {
	expect(
		macros: [
			"Default": DefaultMacro.self,
		],
	) {
"""
@Default
struct Foo {
 var a: Int = 9
 var b: Bool?
 var c: [String]
 var d: OrderedDictionary<String, String> 
}
"""
	} expansion: {
"""
struct Foo {
 var a: Int = 9
 var b: Bool?
 var c: [String]
 var d: OrderedDictionary<String, String> 
}

extension Foo : Default {
\tstatic let `default`: Foo = .init(b: nil, c: [], d: [:])
}
"""
	}
	
}


@Test func defaultMacro_ignoreComputedProperty() {
	expect(
		macros: [
			"Default": DefaultMacro.self,
		],
	) {
"""
@Default
struct Foo {
 var a: Int = 9
 var b: Bool?
 let c: String
 var d: Int { 3 }
}
"""
	} expansion: {
"""
struct Foo {
 var a: Int = 9
 var b: Bool?
 let c: String
 var d: Int { 3 }
}

extension Foo : Default {
\tstatic let `default`: Foo = .init(b: nil, c: "")
}
"""
	}
	
}
