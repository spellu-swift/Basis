

extension Array {
	
	@inlinable
	public static func capacity(
		_ capacity: Int,
	) -> Self {
		var this = Self()
		this.reserveCapacity(capacity)
		return this
	}
	
	@inlinable
	public static func capacity(
		_ collection: some Collection,
	) -> Self {
		Self.capacity(collection.count)
	}
	
	@inlinable
	public static func count(
		_ count: Int,
		repeating element: Element,
	) -> Self {
		Self(repeating: element, count: count)
	}
	
	@inlinable
	public static func count(
		_ collection: some Collection,
		repeating element: Element,
	) -> Self {
		Self(repeating: element, count: collection.count)
	}
	
	@inlinable
	public static func count(
		_ count: Int,
	) -> Self where Element : Default {
		Self(repeating: Element.default, count: count)
	}
	
	@inlinable
	public static func count(
		_ collection: some Collection,
	) -> Self where Element : Default {
		Self(repeating: Element.default, count: collection.count)
	}
	
}


extension Array {

	@inlinable
	public init(
		capacity: Int,
	) {
		self.init()
		reserveCapacity(capacity)
	}

	@inlinable
	public init(
		capacity: Int,
		initializer: (_ buffer: UnsafeMutableBufferPointer<Element>) throws -> Int,
	) rethrows {
		try self.init(unsafeUninitializedCapacity: capacity) { buffer, count in
			count = try initializer(buffer)
		}
	}
	
	/// 安全な要素取得。
	/// at: -1 という指定もできる。
	@inlinable
	public func get(
		at index: Int,
	) -> Element? {
		let index: Int = index >= 0 ? index : count + index
		
		return self.indices ~= index ? self[index] : nil
	}

	/// 要素を追加したものを取得。
	@inlinable
	public func appending(
		_ items: Element...,
	) -> Self {
		self + items
	}
	
	/// nil除去。
	@inlinable
	public func compacted<T>(
	) -> [T] where Element == Optional<T> {
		compactMap{$0}
	}
	
//	/// 最初n個を取得
//	@inlinable
//	public func first(
//		_ k: Int
//	) -> ArraySlice<Element> {
//		guard count - k >= 0 else { return ArraySlice(self) }
//		
//		return dropLast(count - k)
//	}
//	
//
//	/// 最後n個を取得
//	@inlinable
//	public func last(
//		_ k: Int
//	) -> ArraySlice<Element> {
//		guard count - k >= 0 else { return ArraySlice(self) }
//		return dropFirst(count - k)
//	}

	/// 分割
	@inlinable
	public func divide(
		first left: Int,
	) -> ([Element], [Element]) {
		(
			first(left).asArray,
			last(count - left).asArray
		)
	}
	
	/// 分割
	@inlinable
	public func divide(
		last right: Int,
	) -> ([Element], [Element]) {
		divide(first: count - right)
	}
	
	/// 分割
	public func divide(
		choise: (Element) throws -> Bool,
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

	/// 順次実行、要素間の処理付き
	public func forEach(
		_ body: (Element) throws -> Void,
		inject: () -> Void,
	) rethrows {
		if
			let first = self.first
		{
			try body(first)
			
			try self.dropFirst().forEach { next in
				inject()
				
				try body(next)
			}
		}
	}
	
	/// 各要素の更新
	public mutating func modifyAll<E>(
		_ perform: (inout Element) throws(E) -> Void,
	) throws(E) {
		for index in indices {
			var element: Element = self[index]
			try perform(&element)
			self[index] = element
		}
	}
	
	/// 各要素の更新
	public mutating func modifyAll<E>(
		_ perform: (Index, inout Element) throws(E) -> Void,
	) throws(E) {
		for index in indices {
			var element: Element = self[index]
			try perform(index, &element)
			self[index] = element
		}
	}
	
	/// 診断
	@inlinable
	public func inspect(
		_ perform: (Self) -> Void,
	) -> Self {
		perform(self)
		return self
	}

}


extension Array {

	/// popLast()に対応したメソッド
	/// パフォーマンスが良くないことに注意。
	public mutating func popFirst() -> Element? {
		if isEmpty {
			return nil
		}
		else {
			let element: Element = self[0]
			remove(at: 0)
			return element
		}
	}
	
	
}


// MARK: - タプル配列


extension Array {
	
	@inlinable
	public func asDictionary<Key : Hashable, Value>(
	) -> Dictionary<Key, Value> where Element == (Key, Value) {
		.init(self)
	}
	
	@inlinable
	public func asDictionary<Key : Hashable, Value>(
		merge: MergeMethod,
	) -> Dictionary<Key, Value> where Element == (Key, Value) {
		.init(self, merge: merge)
	}
	
	@inlinable
	public func asDictionary<Key : Hashable, Value>(
		choice: (Value, Value) -> Value,
	) -> Dictionary<Key, Value> where Element == (Key, Value) {
		.init(self, choice: choice)
	}
	
	@inlinable
	public func asDictionary<Value>(
	) -> Dictionary<String, Value> where Element == (Substring, Value) {
		asStringKeyed().asDictionary()
	}
	
	@inlinable
	public func asOrderedDictionary<Key : Hashable, Value>(
	) -> OrderedDictionary<Key, Value> where Element == (Key, Value) {
		.init(self)
	}
	
	@inlinable
	public func asOrderedDictionary<Key : Hashable, Value>(
		merge: MergeMethod,
	) -> OrderedDictionary<Key, Value> where Element == (Key, Value) {
		.init(self, merge: merge)
	}
	
	@inlinable
	public func asOrderedDictionary<Key : Hashable, Value>(
		choice: (Value, Value) -> Value,
	) -> OrderedDictionary<Key, Value> where Element == (Key, Value) {
		.init(self, choice: choice)
	}
	
	@inlinable
	public func asOrderedDictionary<Value>(
	) -> OrderedDictionary<String, Value> where Element == (Substring, Value) {
		asStringKeyed().asOrderedDictionary()
	}
	
	@inlinable
	internal func asStringKeyed<Value>(
	) -> [(String, Value)] where Element == (Substring, Value) {
		map {
			($0.0.asString, $0.1)
		}
	}
	
}


// MARK: 演算子

extension Array {
	
	/// 単一エレメントも配列同様に+=演算子で追加できるようにしたい！
	@inlinable
	public static func += (
		container: inout Array<Element>,
		element: Element
	) {
		container.append(element)
	}
	
}


// MARK: 基本操作

extension Array {

	@inlinable
	@discardableResult
	public mutating func push(
		_ value: Element
	) -> Element {
		self.append(value)
		return value
	}
	
	@inlinable
	@discardableResult
	public mutating func pop(
	) -> Element? {
		self.popLast()
	}
	
	@discardableResult
	public mutating func modify(
		at index: Index,
		perform: (inout Element) -> Void,
	) -> Element? {
		switch self.get(at: index) {
			case .some(let value):
				var newValue = value
				perform(&newValue)
				self[index] = newValue
				return newValue
				
			case .none:
				return nil
		}
	}
	
	@discardableResult
	public mutating func modify(
		at index: Index,
		perform: (Index, inout Element) -> Void,
	) -> Element? {
		switch self.get(at: index) {
			case .some(let value):
				var newValue = value
				perform(index, &newValue)
				self[index] = newValue
				return newValue
				
			case .none:
				return nil
		}
	}
	
//	public mutating func modify(
//		at index: Index,
//		perform: (inout Element) -> Void,
//	) {
//		switch self.get(at: index) {
//			case .some(let value):
//				var newValue = value
//				perform(&newValue)
//				self[index] = newValue
//				
//			case .none:
//				break
//		}
//	}
//	
//	public mutating func modify(
//		at index: Index,
//		perform: (Index, inout Element) -> Void,
//	) {
//		switch self.get(at: index) {
//			case .some(let value):
//				var newValue = value
//				perform(index, &newValue)
//				self[index] = newValue
//				
//			case .none:
//				break
//		}
//	}
}


extension Array {
	
	/// 配列内の次の値を取得する
	public func next(
		_ value: Element?,
		loop: Bool = false,
	) -> Element? where Element : Equatable {
		let newIndex: Int? = { () -> Int? in
			guard
				let value: Element = value,
				let index: Int = firstIndex(\.self, value)
			else { return isEmpty ? nil : 0 }
			
			if index == endIndex - 1 {
				return loop ? 0 : nil
			}
			
			return index + 1
		}()
		
		return newIndex.map{ self[$0] }
	}
	
	/// 配列内の前の値を取得する
	public func previous(
		_ value: Element?,
		loop: Bool = false,
	) -> Element? where Element : Equatable {
		let newIndex: Int? = { () -> Int? in
			guard
				let value: Element = value,
				let index: Int = firstIndex(\.self, value)
			else { return isEmpty ? nil : endIndex - 1 }
			
			if index == 0 {
				return loop ? endIndex - 1 : nil
			}
			
			return index - 1
		}()
		
		return newIndex.map{ self[$0] }
	}

	/// 配列内の次の値を取得する
	public func next<Value : Equatable>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
		loop: Bool = false,
	) -> Value? {
		let newIndex: Int? = { () -> Int? in
			guard
				let value: Value = value,
				let index: Int = firstIndex(keyPath, value)
			else { return isEmpty ? nil : 0 }
			
			if index == endIndex - 1 {
				return loop ? 0 : nil
			}
			
			return index + 1
		}()
		
		return newIndex.map{ self[$0][keyPath: keyPath] }
	}
	
	/// 配列内の前の値を取得する
	public func previous<Value : Equatable>(
		_ keyPath: KeyPath<Element, Value>,
		_ value: Value?,
		loop: Bool = false,
	) -> Value? {
		let newIndex: Int? = { () -> Int? in
			guard
				let value: Value = value,
				let index: Int = firstIndex(keyPath, value)
			else { return isEmpty ? nil : endIndex - 1 }
			
			if index == 0 {
				return loop ? endIndex - 1 : nil
			}
			
			return index - 1
		}()
		
		return newIndex.map{ self[$0][keyPath: keyPath] }
	}
	
}



