

extension ArraySlice {
	
	
	public var asArray: [Element] {
		Array(self)
	}
	
	
}


extension ArraySlice {
	
	
	/// 安全な要素取得
	@available(*, deprecated)
	@inlinable
	public func get(
		at index: Int
	) -> Element? {
		let index: Int = index >= 0 ? index : count + index
		
		return self.indices ~= index ? self[index] : nil
	}
	

	/// 安全な要素取得
	@inlinable
	public func first(
		at index: Int
	) -> Element? {
		guard 0 <= index && index < count
		else { return nil }
		
		return self[index]
	}
	
	
	/// 安全な要素取得
	@inlinable
	public func last(
		at index: Int
	) -> Element? {
		let index: Int = count - 1 - index
		
		guard 0 <= index && index < count
		else { return nil }
		
		return self[index]
	}
	
	
	/// 最初n個を取得
	@inlinable
	public func first(
		_ k: Int
	) -> ArraySlice<Element> {
		guard count - k >= 0 else { return ArraySlice(self) }
		
		return dropLast(count - k)
	}
	
	
	/// 最後n個を取得
	@inlinable
	public func last(
		_ k: Int
	) -> ArraySlice<Element> {
		guard count - k >= 0 else { return ArraySlice(self) }
		return dropFirst(count - k)
	}
	
	
	/// 先頭落とし
	@inlinable
	public func drop(
		first: Int
	) -> ArraySlice<Element> {
		return dropFirst(first)
	}
	
	
	/// 末尾落とし
	@inlinable
	public func drop(
		last: Int
	) -> ArraySlice<Element> {
		return dropLast(last)
	}


	/// 分割
	@inlinable
	public func divide(
		first left: Int
	) -> ([Element], [Element]) {
		return (
			first(left).asArray,
			last(count - left).asArray
		)
	}
	
	
	/// 分割
	@inlinable
	public func divide(
		last right: Int
	) -> ([Element], [Element]) {
		return divide(first: count - right)
	}
	
	
	/// 分割
	public func divide(
		choise: (Element) throws -> Bool
	) rethrows -> ([Element], [Element]) {
		var left: [Element] = []
		var right: [Element] = []
		
		for element in self {
			if try choise(element) {
				left.append(element)
			}
			else {
				right.append(element)
			}
		}
		
		return (left, right)
	}
	

}
