

///
extension Error {
	
	/// 読みやすいメッセージ
	/// NOTE: (error as? CustomStringConvertible) というコードは、コンパイラに "always successful" と言われてしまう。(2022.2.26)
	/// ↑ しかし、実際にはfalseが返されることがある。
	public var readableMessage: String {
		if let this = self as? any ProgramError {
			this.readableMessage
		}
		else if let this = self as? CustomStringConvertible {
			"Error \(category): " + this.description
		}
		else {
			"Error \(category): " + String(describing: self)
		}
	}
	
}
