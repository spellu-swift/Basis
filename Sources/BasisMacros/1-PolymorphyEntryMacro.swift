import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


public struct PolymorphyEntryMacro {}


extension PolymorphyEntryMacro : AccessorMacro {
	
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext,
	) throws -> [SwiftSyntax.AccessorDeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let identifier = varDecl.identifier
		else {
			return []
		}
		
		// Generate custom accessors for the stored property
		return [
			AccessorDeclSyntax(stringLiteral: """
get { self[__Key_\(identifier).self] }
"""),
			AccessorDeclSyntax(stringLiteral: """
set { self[__Key_\(identifier).self] = newValue }
"""),
		]
	}
	
}


extension PolymorphyEntryMacro : PeerMacro {
	
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext,
	) throws -> [DeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self)
		else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(
						node: declaration,
						message: PolymorphyEntryMacroError.onlyVarDeclaration,
					)
				]
			)
		}
		
		guard
			let identifier = varDecl.identifier,
			let type = varDecl.type,
			let initializer = varDecl.initializer
		else {
			throw DiagnosticsError(
				diagnostics: [
					Diagnostic(
						node: varDecl,
						message: PolymorphyEntryMacroError.missingDefaultValue,
						fixIt: .replace(
							message: PolymorphyEntryMacroFixIt.provideDefaultValue,
							oldNode: varDecl,
							//							newNode: DeclSyntax(stringLiteral: "\(varDecl) = <#Default Value#>")
							newNode: DeclSyntax(stringLiteral: "\(varDecl) = .default")
						)
					)
				]
			)
		}
		
		return [
			DeclSyntax(stringLiteral: """
private struct __Key_\(identifier) : PolymorphyKey {
static var defaultValue: \(type.trimmedDescription) { \(initializer.trimmedDescription) }
}
"""),
		]
	}
	
}


public enum PolymorphyEntryMacroError : String, Swift.Error {
	
	case onlyVarDeclaration = "`@PolymorphyEntry`: Can only be applied to a 'var' declaration"
	case missingDefaultValue = "`@PolymorphyEntry`: Property missing a default value"
	
}


extension PolymorphyEntryMacroError : DiagnosticMessage {
	
	public var message: String { self.rawValue }
	
	public var diagnosticID: MessageID {
		MessageID(domain: "Spellu", id: "\(type(of: self)).\(self)")
	}
	
	public var severity: DiagnosticSeverity { .error }
	
}


public enum PolymorphyEntryMacroFixIt : String {
	
	case provideDefaultValue = "Provide default value"
	
}


extension PolymorphyEntryMacroFixIt : FixItMessage {
	
	public var message: String { self.rawValue }
	
	public var fixItID: MessageID {
		MessageID(domain: "Spellu", id: "\(type(of: self)).\(self)")
	}
	
}
