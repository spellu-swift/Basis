import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct PrintMacro : ExpressionMacro {

	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext,
	) -> ExprSyntax {
#if DEBUG
		return """
Debugging.print(\(node.arguments))
"""
#else
		return """
()
"""
#endif
	}
	
}
