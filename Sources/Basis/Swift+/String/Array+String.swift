

// MARK: - Character配列


extension Array where Element == Character {

	@inlinable
	public var asString: String {
		String(self)
	}
	
}


// MARK: - Substring配列


extension Array where Element == Substring {
	
	@inlinable
	public var asString: [String] {
		map{ String($0) }
	}
	
}


// MARK: - (any StringProtocol)配列


extension Array where Element : StringProtocol {

	/// 各要素にterminatorを付加して連結する
	@inlinable
	public func joined(
		terminator: String = "",
	) -> String {
		if isEmpty {
			""
		}
		else {
			joined(separator: terminator) + terminator
		}
	}

	/// 各要素に改行をつけて単一文字列に変換する
	@inlinable
	public var asText: String {
		joined(terminator: "\n")
	}

}
