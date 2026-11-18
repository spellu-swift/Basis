import RegexBuilder


// MARK: Trim
extension StringProtocol where Self.SubSequence == Substring {
	
	@inlinable
	public var trimmed: String {
		trimmed(#/\s+/#)
	}
	
	// 前後の空白を除去する
	@inlinable
	public func trimmed(
		_ pattern: some RegexComponent,
	) -> String {
		self
			.trimmingPrefix(pattern)
			.trimmingSuffix(pattern)
			.asString
	}
	
}


//extension StringProtocol where Self.SubSequence == Substring {
//
//	public func trimming(
//		prefixWhile characterSet: CharacterSet,
//	) -> Substring {
//	}
//	
//}


extension StringProtocol where Self.SubSequence == Substring {
	
	@inlinable
	public func trimming(
		_ string: String,
	) -> Substring {
		self
			.trimmingPrefix(string)
			.trimmingSuffix(string)
	}

	public func trimmingPrefix(
		_ string: String,
	) -> Substring {
		let index = index(startIndex, offsetBy: string.count)

		if self[..<index] == string {
			return self[index...]
		}
		else {
			return self[...]
		}
	}
	
	public func trimmingSuffix(
		_ string: String,
	) -> Substring {
		let index = index(endIndex, offsetBy: -string.count)

		if self[index...] == string {
			return self[..<index]
		}
		else {
			return self[...]
		}
	}
	
}
extension StringProtocol where Self.SubSequence == Substring {
	
	@inlinable
	public func trimming(
		_ regex: some RegexComponent,
	) -> Substring {
		self
			.trimmingPrefix(regex)
			.trimmingSuffix(regex)
	}
	
	public func trimmingPrefix(
		_ regex: some RegexComponent,
	) -> Substring {
		let regex = Regex {
			Anchor.startOfSubject
			regex
		}
		
		if
			let match = self.firstMatch(of: regex)
		{
			return self[match.range.upperBound...]
		}
		else {
			return self[...]
		}
	}
	
	public func trimmingSuffix(
		_ regex: some RegexComponent,
	) -> Substring {
		let regex = Regex {
			regex
			Anchor.endOfSubject
		}

		if
			let match = self.firstMatch(of: regex)
		{
			return self[..<match.range.lowerBound]
		}
		else {
			return self[...]
		}
	}
	
}


// TODO: CharacterSet
extension StringProtocol where Self.SubSequence == Substring {
	
}


