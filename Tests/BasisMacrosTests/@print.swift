import MacroTesting
import BasisMacros


@Test func printMacro() {
	expect(
		macros: [
			"print": PrintMacro.self,
		]
	) {
"""
			#print(10, "abc", nilString: "<nil>")
"""
	} expansion: {
"""
			Debugging.print(10, "abc", nilString: "<nil>")
"""
	}
}


@Test func printMacro_release() {
	let _ = ()
	
	()
	
	_ = 1
}
