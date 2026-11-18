
/*
 Collection
├ first(transform:)
├ last(transform:)
├ contains(keyPath:value:)
├ first(keyPath:value:)
├ last(keyPath:value:)
├ all(keyPath:value:)
├ filter(keyPath:value:)
├ map(keyPath:)
├ uniqued
└ sorted
├ isNotEmpty
├ first(k)
├ last(k)
├ drop(first:)
├ drop(last:)
├ firstIndex
├ lastIndex
└ allIndex

RandomAccessCollection
└ binarySearch
└ chunk

RangeReplaceableCollection
└ insert/remove/replace/clear
*/

extension Collection {
	
	/// 空ではないか
	@inlinable
	public var isNotEmpty: Bool {
		isEmpty == false
	}
	
	/// 各要素を変換し、nilでない最初の要素を取得
	public func first<T>(
		_ transform: @Sendable (Element) -> T?
	) -> T? {
		for e in self {
			if
				let v = transform(e)
			{
				return v
			}
		}
		
		return nil
	}
	
	/// 各要素を変換し、nilでない最後の要素を取得
	public func last<T>(
		_ transform: @Sendable (Element) -> T?
	) -> T? {
		for e in self.reversed() {
			if
				let v = transform(e)
			{
				return v
			}
		}
		
		return nil
	}
	
	/// 最初n個を取得
	@inlinable
	public func first(
		_ k: Int
	) -> SubSequence {
		self[startIndex..<index(startIndex, offsetBy:k)]
	}
	
	/// 最後n個を取得
	@inlinable
	public func last(
		_ k: Int
	) -> SubSequence {
		self[index(endIndex, offsetBy:-k)...]
	}
	
	/// 先頭落とし
	@inlinable
	public func drop(
		first: Int
	) -> SubSequence {
		dropFirst(first)
	}
	
	/// 末尾落とし
	@inlinable
	public func drop(
		last: Int
	) -> SubSequence {
		dropLast(last)
	}
	
}


extension Collection {
	
	/// 一致する要素が含まれているか
	@inlinable
	public func contains<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> Bool where Value : Equatable {
		contains{ $0[keyPath: keyPath] == value }
	}
	
	/// 最初に一致する要素を取得
	@inlinable
	public func first<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> Element? where Value : Equatable {
		first{ $0[keyPath: keyPath] == value }
	}
	
	/// 最後に一致する要素を取得
	@inlinable
	public func last<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> Element? where Value : Equatable {
		reversed().first{ $0[keyPath: keyPath] == value }
	}
	
	/// 一致するすべての要素を取得
	@inlinable
	public func all<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> [Element] where Value : Equatable {
		compactMap{ $0[keyPath: keyPath] == value ? $0 : nil }
	}
	
	/// 最初に一致する要素のインデックスを取得
	@inlinable
	public func firstIndex<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> Index? where Value : Equatable {
		firstIndex{ $0[keyPath: keyPath] == value }
	}
	
	/// 最後に一致する要素のインデックスを取得
	@inlinable
	public func lastIndex<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> Index? where Value : Equatable, Index == Array<Element>.Index {
		reversed().firstIndex{ $0[keyPath: keyPath] == value }
	}
	
	/// 一致するすべての要素のインデックスを取得
	@inlinable
	public func allIndex<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> [Index] where Value : Equatable, Index == Array<Element>.Index {
		enumerated().compactMap{ $1[keyPath: keyPath] == value ? $0 : nil }
	}
	
	/// 指定要素でフィルタする
	@inlinable
	public func filter<Value>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
	) -> [Self.Element] where Value : Equatable {
		self.filter {
			$0[keyPath: keyPath] == value
		}
	}

}


///
/// insert(at:_)
/// remove(at)
///
/// 語順大事
///

extension RangeReplaceableCollection {

	@inlinable
	public mutating func insert(
		at index: Index,
		_ element: Element
	) {
		self.insert(element, at: index)
	}
	
	@inlinable
	public mutating func clear(
	) {
		removeAll()
	}

	@inlinable
	public mutating func remove(
		first: Int
	) {
		remove(0..<first)
	}
	
	@inlinable
	public mutating func remove(
		last: Int
	) {
		removeSubrange(
			index(endIndex, offsetBy: -last)
			..<
			endIndex
		)
	}

	/// 一致するすべての要素を削除
	@inlinable
	public mutating func remove<Value>(
		_ keyPath: KeyPath<Element, Value>,
		all value: Value,
	) where Value : Equatable {
		removeAll{ $0[keyPath: keyPath] == value }
	}

	@inlinable
	public mutating func remove(
		_ range: Range<Int>
	) {
		removeSubrange(
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound)
		)
	}
	
	@inlinable
	public mutating func remove(
		_ range: any RangeExpression<Int>
	) {
		let range: Range<Int>
		= range.relative(to: 0..<count)

		removeSubrange(
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound)
		)
	}
	
	@inlinable
	public mutating func remove(
		_ range: any RangeExpression<Index>
	) {
		removeSubrange(range)
	}
	
	@inlinable
	public mutating func replace<C>(
		_ range: Range<Index>,
		_ elements: C
	) where C : Collection, Self.Element == C.Element {
		replaceSubrange(range, with: elements)
	}
	
	@inlinable
	public mutating func replace<C>(
		_ range: any RangeExpression<Int>,
		_ elements: C
	) where C : Collection, Self.Element == C.Element {
		let range: Range<Int>
		= range.relative(to: 0..<count)
		
		replaceSubrange(
			index(startIndex, offsetBy: range.lowerBound)
			..<
			index(startIndex, offsetBy: range.upperBound),
			with: elements
		)
	}
	
	@inlinable
	public mutating func replace<C>(
		_ range: any RangeExpression<Index>,
		_ elements: C
	) where C : Collection, Self.Element == C.Element {
		replaceSubrange(range, with: elements)
	}
	
}


extension RangeReplaceableCollection where Index == Int {
	
	@inlinable
	public mutating func remove(
		_ range: any RangeExpression<Index>
	) {
		removeSubrange(range)
	}
	
	@inlinable
	public mutating func replace<C>(
		_ range: any RangeExpression<Index>,
		_ elements: C
	) where C : Collection, Self.Element == C.Element {
		replaceSubrange(range, with: elements)
	}
	
}


// MARK: Unique

extension Sequence {
	
	/// 同一値を削除した配列
	/// Rustのdeduq()
	public func uniqued(
	) -> [Element] where Element : Hashable {
		var seen = Set<Element>()
		
		return self.filter{ seen.insert($0).inserted }
	}
	
	/// 同一キー値を削除した配列
	// NOTE: where K : Equatable にしたいが、SetがHashableを要求してきた。
	public func uniqued<K>(
		by key: (Element) -> K
	) -> [Element] where K : Hashable {
		var seen = Set<K>()
		
		return self.filter{ seen.insert(key($0)).inserted }
	}
	
}


extension Array {
	
	/// 同一値を削除した配列
	public mutating func unique(
	) where Element : Hashable {
		var seen = Set<Element>()
		
		self = self.filter{ seen.insert($0).inserted }
	}
	
	/// 同一キー値を削除した配列
	// NOTE: where K : Equatable にしたいが、SetがHashableを要求してきた。
	public mutating func unique<K>(
		by key: (Element) -> K
	) where K : Hashable {
		var seen = Set<K>()
		
		self = self.filter{ seen.insert(key($0)).inserted }
	}
	
}


// MARK: Sort

extension Sequence {

	/// キー関数を使った昇順ソート
	public func sorted<K>(
		order: Ordering = .less,
		by f: (Element) -> K
	) -> [Element] where K : Orderable {
		sorted {
			(f($0) <=> f($1)) == order
		}
	}
	
	/// 比較関数を使った昇順ソート
	public func sorted(
		order: Ordering = .less,
		by f: (Element, Element) -> Ordering
	) -> [Element] {
		sorted {
			f($0, $1) == order
		}
	}
	
}

extension Array {
	
	/// キー関数を使った昇順ソート
	public mutating func sort<K>(
		order: Ordering = .less,
		by f: (Element) -> K
	) where K : Orderable {
		sort {
			(f($0) <=> f($1)) == order
		}
	}
	
	/// 比較関数を使った昇順ソート
	public mutating func sort(
		order: Ordering = .less,
		by f: (Element, Element) -> Ordering
	) {
		sort {
			f($0, $1) == order
		}
	}
	
}


// MARK: Binary Search

public enum BinarySearchResult : Equatable {
	case found(Int)
	case notFound(Int)
}


extension RandomAccessCollection {

	/// 値を使ったバイナリサーチ
	@inlinable
	public func binarySearch(
		_ target: Element
	) -> BinarySearchResult where Element : Orderable {
		binarySearch{ $0 <=> target }
	}
	
	
	/// 比較関数を使ったバイナリサーチ
	@inlinable
	public func binarySearch(
		by compare: (Element) -> Ordering
	) -> BinarySearchResult {
		if isEmpty { return .notFound(0) }
		
		var lowerIndex: Int = 0
		var upperIndex: Int = self.count - 1
		
		while true {
			let index = (lowerIndex + upperIndex) / 2
			let element = self[
				self.index(self.startIndex, offsetBy: index)
			]
			
			let result: Ordering = compare(element)
			
			if result.isEqual {
				return .found(index)
			}
			else if lowerIndex > upperIndex {
				return .notFound(lowerIndex)
			}
			else {
				if result.isLess {
					lowerIndex = index + 1
				}
				else {
					upperIndex = index - 1
				}
			}
		}
	}
	
	
	/// キー関数を使ったバイナリサーチ
	public func binarySearch<Key>(
		_ target: Key,
		by compare: (Element) -> Key
	) -> BinarySearchResult where Key : Orderable {
		binarySearch { compare($0) <=> target }
	}
}


extension RandomAccessCollection where Index == Int {

	/// 指定サイズごとに要素をパックする
	public func chunked(
		into size: Int,
	) -> [[Element]] {
		Swift.stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
	
}
