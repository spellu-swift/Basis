

extension String {
	
	public struct Token<Content> {
		public init(
			range: Range<String.Index>,
			content: Content,
		) {
			self.range = range
			self.content = content
		}

		public var range: Range<String.Index>
		public var content: Content
	}
	
	/// 文字列を字句を抽出する
	public func tokenize<Content>(
		rules: [(String, (Regex<AnyRegexOutput>.Match) -> Content)],
		default: (String) -> Content,
	) -> [Token<Content>] {
		let input: Substring = self[...]
		var result: [Token<Content>] = []
		var position: String.Index = input.startIndex
		
		while position < input.endIndex {
			// 次のマッチ位置を探す
			guard
				let match: Token<Content> = input[position...].match(
					rules: rules
				)
			else { break }
			
			// マッチした開始位置の前の文字列を追加する
			if position < match.range.lowerBound {
				let range = position..<match.range.lowerBound
				
				result.append(
					Token(
						range: range,
						content: `default`(input[range].asString)
					)
				)
			}
			
			// マッチしたTokenを追加する
			result.append(match)
			
			// 次の検索の開始インデックスを設定する
			position = match.range.upperBound
		}
		
		// 残りのStringを追加する
		if position < input.endIndex {
			let range = position..<input.endIndex
			
			result.append(
				Token(
					range: range,
					content: `default`(input[range].asString)
				)
			)
		}
		
		// 結果を返す
		return result
	}
	
}
extension Substring {

	/// ルールにマッチした最初の要素を返す
	fileprivate func match<Content>(
		rules: [(String, (Regex<AnyRegexOutput>.Match) -> Content)],
	) -> String.Token<Content>? {
		var matchTokens: [String.Token<Content>] = []
		
		for rule in rules {
			guard
				let pattern = try? Regex(rule.0),
				let result = self.matches(of: pattern).first(where: { !$0.range.isEmpty })
			else { continue }
			
			matchTokens.append(String.Token(
				range: result.range,
				content: rule.1(result)
			))
		}
		
		if matchTokens.count == 0 {
			return nil
		}
		
		return matchTokens.sorted{$0.range.lowerBound < $1.range.lowerBound}[0]
	}

}
