import MacroTesting
import BasisMacros


@Test("@PolymorphyEntryのマクロ展開")
func PolymorphyEntryMacro_1() {
	expect(
		macros: [
			"PolymorphyEntry": PolymorphyEntryMacro.self,
		],
		indentationWidth: .tabs(1),
	) {
"""
extension PolymorphyValues {
	@PolymorphyEntry var number: Int = 123
}
"""
	} expansion: {
"""
extension PolymorphyValues {
	var number: Int {
		get {
			self[__Key_number.self]
		}
		set {
			self[__Key_number.self] = newValue
		}
	}

	private struct __Key_number : PolymorphyKey {
		static var defaultValue: Int {
			123
		}
	}
}
"""
	}
}


@Test("@PolymorphyEntryのマクロ展開")
func PolymorphyEntryMacro_2() {
	expect(
		macros: [
			"PolymorphyEntry": PolymorphyEntryMacro.self,
		],
		indentationWidth: .tabs(1),
	) {
"""
extension PolymorphyValues {
	@PolymorphyEntry var number: () -> Int = { 123 }
}
"""
	} expansion: {
"""
extension PolymorphyValues {
	var number: () -> Int {
		get {
			self[__Key_number.self]
		}
		set {
			self[__Key_number.self] = newValue
		}
	}

	private struct __Key_number : PolymorphyKey {
		static var defaultValue: () -> Int {
			{
				123
			}
		}
	}
}
"""
	}
}


@Test("@PolymorphyEntryのマクロ展開")
func PolymorphyEntryMacro_3() {
	expect(
		macros: [
			"PolymorphyEntry": PolymorphyEntryMacro.self,
		],
		diagnostics: [
			DiagnosticSpec(
				message: PolymorphyEntryMacroError.missingDefaultValue.rawValue,
				line: 2, column: 2,
				fixIts: [
					FixItSpec(message: PolymorphyEntryMacroFixIt.provideDefaultValue.rawValue)
				]
			)
		],
		indentationWidth: .tabs(1),
	) {
"""
extension PolymorphyValues {
	@PolymorphyEntry var number: Int
}
"""
	} expansion: {
"""
extension PolymorphyValues {
	var number: Int {
		get {
			self[__Key_number.self]
		}
		set {
			self[__Key_number.self] = newValue
		}
	}
}
"""
	}
}
