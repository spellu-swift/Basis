import MacroTesting
import BasisMacros


@Test("@Polymorphyのマクロ展開")
func PolymorphyMacro_1() {
	expect(
		macros: [
			"Polymorphy": PolymorphyMacro.self,
		],
		indentationWidth: .tabs(1),
	) {
"""
class ExampleAutomaton {
	@Polymorphy(\\.now, method: MainActor.polymorphyValue, cached: false) var now
}
"""
	} expansion: {
"""
class ExampleAutomaton {
	var now {
		get {
			MainActor.polymorphyValue(\\.now)
		}
	}
}
"""
	}
}


@Test("@Polymorphyのマクロ展開")
func PolymorphyMacro_2() {
	expect(
		macros: [
			"Polymorphy": PolymorphyMacro.self,
		],
		indentationWidth: .tabs(1),
	) {
"""
class ExampleAutomaton {
	@Polymorphy(\\.now, method: MainActor.polymorphyValue, cached: true) var now
}
"""
	} expansion: {
"""
class ExampleAutomaton {
	var now {
		get {
			_now
		}
	}

	var _now = MainActor.polymorphyValue(\\.now)
}
"""
	}
}


