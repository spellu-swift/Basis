import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct OrderableMacro {}


extension OrderableMacro : ExtensionMacro {

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext,
	) throws -> [ExtensionDeclSyntax] {
		let typeName: String
		let introducer: String
		
		typeName = type.name ?? "#Error#"
		introducer = declaration.introducer.text
		
		let inheritedTypes: [String] = (declaration.inheritanceClause?.inheritedTypes ?? [])
			.compactMap {
				$0.type.name
			}
		
		let genericParameters: [GenericParameterSyntax] = declaration.genericParameter ?? []
		
		let variables: [VariableDeclSyntax] = declaration.variables
			.filter{ $0.identifier != nil && $0.type != nil }
			.filter{ $0.modifiers.names.contains("static") == false }
			.filter{ $0.accessorBlock == nil }
		
		var additionalConformanceProtocols: [String] = [
			"Orderable",
			"Comparable",
		]
		
		if !inheritedTypes.contains("Equatable") && !inheritedTypes.contains("Hashable") {
			additionalConformanceProtocols.append("Equatable")
		}
		
		let extraExtension: ExtensionDeclSyntax
		
		if introducer == "enum" {
			extraExtension = try ExtensionDeclSyntax(
"""
extension \(raw: typeName) : \(raw: additionalConformanceProtocols.joined(separator: " & "))\(raw: whereClause(genericParameters)) {
}
"""
			)
		}
		else {
			extraExtension = try ExtensionDeclSyntax(
"""
extension \(raw: typeName) : \(raw: additionalConformanceProtocols.joined(separator: " & "))\(raw: whereClause(genericParameters)) {
\tpublic static func <=>(
\t\tlhs: Self,
\t\trhs: Self
\t) -> Basis.Ordering {
\t\t.equal
\(raw: variables.map{ compareLine($0) }.joined(separator: "\n"))
\t}

\t@inlinable
\tpublic static func ==(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isEqual
\t}

\t@inlinable
\tpublic static func <(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLess
\t}

\t@inlinable
\tpublic static func <=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isLessThan
\t}

\t@inlinable
\tpublic static func >=(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreaterThan
\t}

\t@inlinable
\tpublic static func >(lhs: Self, rhs: Self) -> Bool {
\t\t(lhs <=> rhs).isGreater
\t}
}
"""
			)
		}
		
		return [extraExtension]
	}
	
	static func whereClause(
		_ parameters: [GenericParameterSyntax],
	) -> String {
		if parameters.isEmpty {
			""
		}
		else {
			" where " + parameters.map{ "\($0.name.text) : Orderable"}.joined(separator: ", ")
		}
	}
	
	static func compareLine(
		_ variable: VariableDeclSyntax,
	) -> String {
		"\t\t\t.compare(lhs, rhs, \\.\(variable.identifier!))"
	}
	
}
