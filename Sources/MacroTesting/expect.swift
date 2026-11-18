import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport


public typealias DiagnosticSpec = SwiftSyntaxMacrosGenericTestSupport.DiagnosticSpec
public typealias NoteSpec = SwiftSyntaxMacrosGenericTestSupport.NoteSpec
public typealias FixItSpec = SwiftSyntaxMacrosGenericTestSupport.FixItSpec


///
/// Swift Testing用のマクロテストメソッド
///
public func expect(
	macros: [String: any Macro.Type],
	diagnostics: [DiagnosticSpec] = [],
	indentationWidth: Trivia = .spaces(4),
	of originalSource: @escaping () -> String,
	expansion expandedSource: @escaping () -> String,
	sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
	expectMacroExpansion(
		originalSource(),
		expandedSource: expandedSource(),
		diagnostics: diagnostics,
		macros: macros,
		indentationWidth: indentationWidth,
		sourceLocation: sourceLocation
	)
}


