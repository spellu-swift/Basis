

// NOTE: (error as? CustomStringConvertible) というコードは、コンパイラに "always successful" と言われてしまう。(2022.2.26)


public protocol ProgramError : Swift.Error, Equatable {
	
	var category: String { get }

	var reason: String? { get }

	var message: String { get }
	
	/// 読みやすいメッセージ
	var readableMessage: String { get }

}


extension Swift.Error {
	
	@inlinable
	public var category: String {
		let typename: String
		= SwiftTypeIdentifier(Self.self).name
		
		return typename.trimmingSuffix("Error").asString
	}
	
}


/// 読みやすいエラー文字列サポート
///
/// error.readableMessage を活用してください。
///
/// "Error <caregory>: <reason>: <parameter>...
/// ex) "Error General: invalidFormat: \"xxx\""
extension ProgramError {
	
	@inlinable
	public var reason: String? {
		let mirror = Mirror(reflecting: self)

		return if
			mirror.displayStyle == .enum
		{
			mirror.children.first?.label ?? String(describing: self)
		}
		else {
			nil
		}
	}
	
	public var arguments: [(label: String?, value: Any)]? {
		let mirror = Mirror(reflecting: self)

		return if
			mirror.displayStyle == .enum
		{
			mirror.enumInfo?.values
		}
		else {
			nil
		}
	}

	@inlinable
	public var message: String {
		if
			let arguments
		{
			if
				let reason
			{
				(["\(reason):"] + arguments.map{label, value in label != nil ? "\(label!)=\(value)" : "\(value)"})
					.joined(separator: " ")
			}
			else {
				arguments.map{label, value in label != nil ? "\(label!)=\(value)" : "\(value)"}
					.joined(separator: " ")
			}
		}
		else {
			reason ?? ""
		}
	}

	public var readableMessage: String {
		["Error", "\(category):", "\(message)"].joined(separator: " ")
	}

}


extension ProgramError {

	/// デバッグ用文字列
	public var debugDescription: String {
		String(describing: self)
	}

	/// 同値判定
	/// NOTE: ユニットテスト用
	public static func == (
		lhs: Self,
		rhs: Self
	) -> Bool {
		lhs.debugDescription == rhs.debugDescription
	}
	
}


private extension Mirror {

	var enumInfo: (name: String, values: [(label: String?, value: Any)])? {
		guard
			displayStyle == .enum
		else { return nil }
		
		for (name, value) in children {
			guard let name else { continue }
			
			let values: [(label: String?, value: Any)] = Mirror(reflecting: value).children.map {
				if ($0.label ?? "").hasPrefix(".") {
					(nil, $0.value)
				}
				else {
					($0.label, $0.value)
				}
			}
			
			return (name: name, values: values.isNotEmpty ? values : [(nil, value)])
		}
		
		return nil
	}
	
}
