extension Regex.Match {

	@inlinable
	public var asAny: AnyRegexOutput {
		AnyRegexOutput(self)
	}

	@inlinable
	public var substrings: [Substring?] {
		asAny.substrings
	}
	
	@inlinable
	public var strings: [String?] {
		asAny.strings
	}

	@inlinable
	public func substring(
		at index: Int
	) -> Substring? {
		asAny.substrings.get(at: index).flatMap{ $0 }
	}
	
	@inlinable
	public func string(
		at index: Int
	) -> String? {
		substring(at: index).map{ String($0) }
	}
	
	@inlinable
	public func range(
		at index: Int
	) -> Range<String.Index>? {
		asAny.get(at: index)?.range
	}
	
}
extension AnyRegexOutput {
	
	@inlinable
	public func get(
		at index: Int
	) -> Element? {
		self.indices ~= index ? self[index] : nil
	}

	@inlinable
	public var substrings: [Substring?] {
		(0..<self.count)
			.map{ self[$0].substring }
	}
	
	@inlinable
	public var strings: [String?] {
		(0..<self.count)
			.map{ self[$0].substring?.asString }
	}
	
}
extension Collection where Self.SubSequence == Substring {
	
	@inlinable
	public func split<Result>(
		separator: String,
		maxSplits: Int = .max,
		omittingEmptySubsequences: Bool = true,
		transform: ([Substring]) throws -> Result,
	) rethrows -> Result {
		try transform(
			split(
				separator: separator,
				maxSplits: maxSplits,
				omittingEmptySubsequences: omittingEmptySubsequences,
			)
		)
	}
	
	@inlinable
	public func split<Result>(
		separator: Substring,
		maxSplits: Int = .max,
		omittingEmptySubsequences: Bool = true,
		transform: ([Substring]) throws -> Result,
	) rethrows -> Result {
		try transform(
			split(
				separator: separator,
				maxSplits: maxSplits,
				omittingEmptySubsequences: omittingEmptySubsequences,
			)
		)
	}
	
}


