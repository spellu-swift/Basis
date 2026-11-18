

extension StringProtocol {
	
	/// 安全な要素取得
	@available(*, deprecated)
	public func get(
		at index: Int,
	) -> Character? {
		let index: Int = index >= 0 ? index : count + index
		
		guard 0 <= index && index < count
		else { return nil }
		
		return self[index]
	}
	
	/// 安全な要素取得
	@inlinable
	public func first(
		at index: Int,
	) -> Character? {
		guard 0 <= index && index < count
		else { return nil }
		
		return self[index]
	}
	
	/// 安全な要素取得
	@inlinable
	public func last(
		at index: Int,
	) -> Character? {
		let index: Int = count - 1 - index
		
		guard 0 <= index && index < count
		else { return nil }
		
		return self[index]
	}
	
	/// prefixマッチ
	@inlinable
	public func hasPrefix(
		_ strings: [any StringProtocol],
	) -> Bool {
		return strings.contains{ self.hasPrefix($0) }
	}

	/// suffixマッチ
	@inlinable
	public func hasSuffix(
		_ strings: [any StringProtocol],
	) -> Bool {
		return strings.contains{ self.hasSuffix($0) }
	}
	
}


// MARK: Type Convertion


extension StringProtocol {

	public var asBool: Bool? {
		switch lowercased() {
			case "true", "yes", "on":
				return true
			case "false", "no", "off":
				return false
			default:
				return nil
		}
	}
	
	@inlinable
	public var asInt: Int? {
		Int(self)
	}

	@inlinable
	public var asDouble: Double? {
		Double(self)
	}

	@inlinable
	public var asBytes: [UInt8] {
		[UInt8](self.utf8)
	}
	
	@inlinable
	public var asBinary: Binary {
		Binary([UInt8](self.utf8))
	}
	
	@inlinable
	public var asString: String {
		String(self)
	}
	
}


// MARK: Index & Range


extension StringProtocol {
	
	// MARK: UTF-8

	@inlinable
	public func utf8Index(
		_ offset: Int,
	) -> String.Index {
		utf8.index(utf8.startIndex, offsetBy: offset)
	}
	
	@inlinable
	public func utf8Offset(
		_ index: String.Index,
	) -> Int {
		utf8.distance(from: utf8.startIndex, to: index)
	}
	
}


extension StringProtocol {

	/// Index with using position of Int type
	@inlinable
	public func index(
		at position: Int,
	) -> String.Index {
		index(
			(position.signum() >= 0 ? startIndex : endIndex),
			offsetBy: Swift.min(count, position)
		)
	}

	@inlinable
	public func range(
		lowerBound: Int,
		upperBound: Int,
	) -> Range<String.Index> {
		self.index(at: lowerBound) ..< self.index(at: upperBound)
	}

	@inlinable
	public func range(
		lowerIndex: String.Index,
		upperIndex: String.Index,
	) -> Range<String.Index> {
		lowerIndex ..< upperIndex
	}

	/// Subscript for using like a "string[i]"
	@inlinable
	public subscript(
		_ position: Int,
	) -> Character {
		let index = index(at: position)
		return self[index]
	}

	/// Subscript for using like a "string[start..<end]"
	@inlinable
	public subscript(
		_ range: CountableRange<Int>,
	) -> Self.SubSequence {
		let start = index(at: range.lowerBound)
		let end = index(at: range.upperBound)
		return self[start..<end]
	}
	
	/// Subscript for using like a "string[start...end]"
	@inlinable
	public subscript(
		_ range: CountableClosedRange<Int>,
	) -> Self.SubSequence {
		let start = index(at: range.lowerBound)
		let end = index(at: range.upperBound)
		return self[start...end]
	}
	
	/// Subscript for using like a "string[start...]"
	@inlinable
	public subscript(
		_ range: PartialRangeFrom<Int>,
	) -> Self.SubSequence {
		let i = index(at: range.lowerBound)
		return suffix(from: i)
	}
	
	/// Subscript for using like a "string[..<end]"
	@inlinable
	public subscript(
		_ range: PartialRangeUpTo<Int>,
	) -> Self.SubSequence {
		let i = index(at: range.upperBound)
		return prefix(upTo: i)
	}
	
	/// Subscript for using like a "string[...end]"
	@inlinable
	public subscript(
		_ range: PartialRangeThrough<Int>,
	) -> Self.SubSequence {
		let i = index(at: range.upperBound)
		return prefix(through: i)
	}

	@inlinable
	public subscript(
		_ ranges: [Range<Int>],
	) -> [Self.SubSequence] {
		ranges.map {
			self[$0]
		}
	}
	
	@inlinable
	public subscript(
		_ ranges: ArraySlice<Range<Int>>,
	) -> [Self.SubSequence] {
		ranges.map {
			self[$0]
		}
	}
	
}


extension StringProtocol {

	@inlinable
	public var singleQuoted: String {
		"'\(self)'"
	}
	
	@inlinable
	public var doubleQuoted: String {
		"\"\(self)\""
	}
	
	@inlinable
	public func wrapped(
		_ char: Character,
	) -> String {
		"\(char)\(self)\(char)"
	}
	
	@inlinable
	public func wrapped(
		_ prefix: Character,
		_ suffix: Character,
	) -> String {
		"\(prefix)\(self)\(suffix)"
	}
	
	@inlinable
	public func wrapped(
		_ string: String,
	) -> String {
		"\(string)\(self)\(string)"
	}
	
	@inlinable
	public func wrapped(
		_ prefix: String,
		_ suffix: String,
	) -> String {
		"\(prefix)\(self)\(suffix)"
	}
	
}
