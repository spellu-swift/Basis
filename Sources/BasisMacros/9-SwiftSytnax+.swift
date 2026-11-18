import SwiftSyntax


extension TypeSyntaxProtocol {
	var name: String? {
		if
			let syntax = self.as(IdentifierTypeSyntax.self)
		{
			syntax.name.text
		}
		else {
			nil
		}
	}
}


extension DeclGroupSyntax {
	var genericParameter: [GenericParameterSyntax]? {
		switch self {
			case let syntax as StructDeclSyntax:
				syntax.genericParameterClause?.parameters.map{ $0 }
				
			case let syntax as EnumDeclSyntax:
				syntax.genericParameterClause?.parameters.map{ $0 }
				
			case let syntax as ClassDeclSyntax:
				syntax.genericParameterClause?.parameters.map{ $0 }
				
			case let syntax as ActorDeclSyntax:
				syntax.genericParameterClause?.parameters.map{ $0 }
				
			default:
				nil
		}
	}
	
	var variables: [VariableDeclSyntax] {
		memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
	}
	
	var functions: [FunctionDeclSyntax] {
		memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
	}
}


/// public, internal, private, fileprivate, static
extension DeclModifierListSyntax {
	func contains(
		token: TokenKind
	) -> Bool {
		self.contains{ $0.name.tokenKind == token }
	}
	
	mutating func remove(
		token: TokenKind
	) {
		if
			let index = self.firstIndex(where: { $0.name.tokenKind == token })
		{
			self.remove(
				at: index
			)
		}
	}
	
	var names: [String] {
		self.map {
			$0.name.text
		}
	}
	
}


/// 変数宣言: let, var
extension VariableDeclSyntax {
	var identifier: String? {
		bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
	}
	
	var type: TypeSyntax? {
		bindings.first?.typeAnnotation?.type
	}
	
	/// ex) "234"
	var initializer: ExprSyntax? {
		bindings.first?.initializer?.value
	}
	
	var accessorBlock: AccessorBlockSyntax? {
		bindings.first?.accessorBlock
	}
}


