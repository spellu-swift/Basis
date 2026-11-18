

///
/// Tree構造の文字列表現機能を表すプロトコル
///
public protocol CustomTreeStringConvertible {
	
	/// Tree構造を文字列表現の配列にレンダリングする
	func renderTree() -> [String]

}


extension CustomTreeStringConvertible {
	
	/// Tree構造を文字列表現で出力する
	public func dumpTree() {
		#print(renderTree().joined(separator: "\n"))
	}

}
