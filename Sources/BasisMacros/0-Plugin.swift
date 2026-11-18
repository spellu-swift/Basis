import SwiftCompilerPlugin
import SwiftSyntaxMacros


@main
struct BasisPlugin : CompilerPlugin {
		
	let providingMacros: [Macro.Type] = [
		PrintMacro.self,
		TraceMacro.self,
		DefaultMacro.self,
		OrderableMacro.self,
		PolymorphyMacro.self,
		PolymorphyEntryMacro.self,
	]
	
}
