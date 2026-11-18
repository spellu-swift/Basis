import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


///
/// DefaultMacro
///
/// - ExtensionMacro
/// - デフォルト値を与えるメンバ
///   - let宣言、var宣言
///
public struct DefaultMacro {}


extension DefaultMacro : ExtensionMacro {
	
	enum GenerateType {
		case declLet
		case declVar
	}

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext,
	) throws -> [ExtensionDeclSyntax] {
		let typeName: String
		= type.trimmedDescription

		var accessModifier: String?
		= declaration.modifiers.names.first
		
		let generateType: GenerateType
		= switch accessModifier {
			case "public":
				.declVar

			default:
				.declLet
		}

		switch accessModifier {
			case "private":
				accessModifier = nil
				
			case "public":
				accessModifier = "public"
				
			default:
				break
		}
		
		// デフォルト値の生成対象となる変数宣言
		let variables: [VariableDeclSyntax]
		= declaration.variables
//			.filter{ $0.bindingSpecifier.text == "var" } // varである
			.filter{ $0.identifier != nil && $0.type != nil }
			.filter{ $0.modifiers.names.contains("static") == false } // staticではない
			.filter{ $0.accessorBlock == nil } // Computed Property ではない

		// デフォルト値の文字列
		let defaultArguments: String
		= initializeArgumentsString(variables)

		// 追加するextension
		let extraExtension: ExtensionDeclSyntax
		= switch generateType {
			case .declLet:
				try ExtensionDeclSyntax("""
extension \(raw: typeName) : Default {
\t\(raw: accessModifier.map{$0 + " "} ?? "")static let `default`: \(raw: typeName) = .init(\(raw: defaultArguments))
}
""")
				
			case .declVar:
				try ExtensionDeclSyntax("""
extension \(raw: typeName) : Default {
\t\(raw: accessModifier.map{$0 + " "} ?? "")static var `default`: \(raw: typeName) {
\t\t.init(\(raw: defaultArguments))
\t}
}
""")
		}
		
		return [extraExtension]
	}
	
	static func initializeArgumentsString(
		_ variables: [VariableDeclSyntax],
	) -> String {
		variables
			.compactMap { variable in
				let name: String = variable.identifier!
				let type: String = variable.type!.trimmedDescription
				let initializer: String? = variable.initializer?.trimmedDescription
				let defaultValue: String? = defaultValue(for: type)
				
				guard
					initializer == nil,
					let defaultValue = defaultValue
				else { return nil }
				
				return "\(name): \(defaultValue)"
			}
			.joined(separator: ", ")
	}
	
	static func defaultValue(
		for type: String,
	) -> String? {
		if type.hasSuffix("?") {
			"nil"
		}
		else if type.first == "[", type.last == "]" {
			type.contains(":") ? "[:]" : "[]"
		}
		else if type.hasPrefix("Array<") && type.hasSuffix(">") {
			"[]"
		}
		else if type.hasPrefix("Dictionary<") && type.hasSuffix(">") {
			"[:]"
		}
		else if type.hasPrefix("OrderedDictionary<") && type.hasSuffix(">") {
			"[:]"
		}
		else {
			switch type {
				case "Bool": "false"
				case
					"Int", "Int8", "Int16", "Int32", "Int64", "Int128",
					"UInt", "UInt8", "UInt16", "UInt32", "UInt64", "UInt128"
					:
					"0"
					
				case
					"Float", "Float32", "Float64", //"Float80",
					"Double"
					:
					"0.0"
					
				case "String":
					"\"\""
					
				default:
					".default"
			}
		}
	}
	
}
