import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


public struct PolymorphyMacro {}


extension PolymorphyMacro : AccessorMacro {
	
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext,
	) throws -> [SwiftSyntax.AccessorDeclSyntax] {
		// varか？
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let identifier = varDecl.identifier
		else {
			return []
		}
		
		// @Polymorphyのパラメータ取得
		guard
			let macroArguments = node.arguments?.as(LabeledExprListSyntax.self)?.map({$0}),
			let keyPath = macroArguments.get(at: 0)?.expression.as(KeyPathExprSyntax.self),
			let method: MemberAccessExprSyntax = macroArguments.get(at: 1)?.expression.as(MemberAccessExprSyntax.self),
			let cached: BooleanLiteralExprSyntax = macroArguments.get(at: 2)?.expression.as(BooleanLiteralExprSyntax.self)
		else {
			return []
		}

		let cachedValue: Bool? = switch cached.literal.tokenKind {
			case .keyword(.true):
				true
			case .keyword(.false):
				false
			default:
				nil
		}
		
		if cachedValue == true {
			return [
				AccessorDeclSyntax(stringLiteral: """
get {
_\(identifier)
}
"""),
			]
		}
		else {
			return [
				AccessorDeclSyntax(stringLiteral: """
get {
\(method.trimmedDescription)(\(keyPath))
}
"""),
				
			]
		}
	}
	
}


extension PolymorphyMacro : PeerMacro {

	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext,
	) throws -> [SwiftSyntax.DeclSyntax] {
		// varか？
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let identifier = varDecl.identifier
		else {
			return []
		}

		// @Polymorphyのパラメータ取得
		guard
			let macroArguments = node.arguments?.as(LabeledExprListSyntax.self)?.map({$0}),
			let keyPath = macroArguments.get(at: 0)?.expression.as(KeyPathExprSyntax.self),
			let method: MemberAccessExprSyntax = macroArguments.get(at: 1)?.expression.as(MemberAccessExprSyntax.self),
			let cached: BooleanLiteralExprSyntax = macroArguments.get(at: 2)?.expression.as(BooleanLiteralExprSyntax.self)
		else {
			return []
		}
		
		let cachedValue: Bool? = switch cached.literal.tokenKind {
			case .keyword(.true):
				true
			case .keyword(.false):
				false
			default:
				nil
		}
		
		if cachedValue == true {
			return [
				DeclSyntax(stringLiteral: """
var _\(identifier) = \(method.trimmedDescription)(\(keyPath))
""")
			]
		}
		else {
			return []
		}

	}
	
}


private extension Array {
	
	func get(
		at index: Int,
	) -> Element? {
		if index < count {
			self[index]
		} else {
			nil
		}
	}
	
}
