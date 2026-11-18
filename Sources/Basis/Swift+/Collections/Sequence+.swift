

/// SwiftUI.ForEachに渡すのに配列が必要なのかな？？
extension Sequence {
	
	@inlinable
	public var indexed: Array<(Int, Element)> {
		Array(enumerated())
	}
	
	@inlinable
	public func indexed(
		prefix: String,
	) -> Array<(id: String, element: Element)> {
		Array(enumerated().map{("\(prefix).\($0)", $1)})
	}
	
}



extension Sequence {

	/// KeyPathを指定してタプルに変換する。
	public func map<each T>(
		_ keyPaths: repeat KeyPath<Element, each T>,
	) -> [(repeat each T)] {
		map { element in
			(repeat element[keyPath: each keyPaths])
		}
	}

	/// KeyPathを指定してDictionaryに変換する。
	@inlinable
	public func mapDictionary<Key, Value>(
		key: KeyPath<Element, Key>,
		value: KeyPath<Element, Value>,
	) -> Dictionary<Key, Value> {
		map { ($0[keyPath: key], $0[keyPath: value]) }
			.asDictionary()
	}
	
	/// KeyPathを指定してOrderedDictionaryに変換する。
	@inlinable
	public func mapOrderedDictionary<Key, Value>(
		key: KeyPath<Element, Key>,
		value: KeyPath<Element, Value>,
	) -> OrderedDictionary<Key, Value> {
		map { ($0[keyPath: key], $0[keyPath: value]) }
			.asOrderedDictionary()
	}
	
}


// MARK: Grouping

//public struct GroupedElement<Key : Hashable, Item : Hashable> {
//		
//	public init(
//		_ key: Key,
//		_ elements: [Item],
//	) {
//		self.key = key
//		self.elements = elements
//	}
//
//	public var key: Key
//	public var elements: [Item]
//		
//}
//
//
//extension GroupedElement : Hashable {}
//
//
//extension Sequence where Element : Hashable {
//		
//	public func group<Key : Hashable>(
//		by key: (Element) -> Key,
//	) -> [GroupedElement<Key, Element>] {
//		var result: [GroupedElement<Key, Element>] = []
//		
//		for element in self {
//			let key = key(element)
//			
//			let index = result.firstIndex{ $0.key == key }
//			
//			if let index = index {
//				result[index].elements.append(element)
//			}
//			else {
//				result.append(.init(key, [element]))
//			}
//		}
//		
//		return result
//	}
//		
//}


extension Sequence {

	/// キーでグルーピングする。
	@inlinable
	public func group<Key : Hashable>(
		by key: (Element) -> Key,
	) -> [(Key, [Element])] {
		group(by: key, transform: {$0})
	}

	/// キーでグルーピングする。
	public func group<Key : Hashable, Value>(
		by key: (Element) -> Key,
		transform: @escaping (Element) throws -> Value,
	) rethrows -> [(Key, [Value])] {
		var result: [(Key, [Value])] = []
		
		for element in self {
			let key = key(element)
			
			let index = result.firstIndex{ $0.0 == key }
			
			if let index = index {
				result[index].1.append(try transform(element))
			}
			else {
				result.append((key, [try transform(element)]))
			}
		}
		
		return result
	}
	
}


extension Sequence {

	/// 指定サイズごとに要素をパックする
	public func chunked(
		into size: Int,
	) -> [[Element]] {
		precondition(size > 0)

		var result: [[Element]] = []
		var chunk: [Element] = []
		chunk.reserveCapacity(size)

		for element in self {
			chunk.append(element)

			if chunk.count == size {
				result.append(chunk)
				chunk = []
				chunk.reserveCapacity(size)
			}
		}

		if chunk.isEmpty == false {
			result.append(chunk)
		}

		return result
	}

}
