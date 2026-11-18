import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct TraceMacro : ExpressionMacro {

	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext,
	) -> ExprSyntax {
#if DEBUG
		return """
Debugging.print(\(node.arguments).renderTree().joined(separator: "\\n"))
"""
#else
		return """
()
"""
#endif
	}
	
}
