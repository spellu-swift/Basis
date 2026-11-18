

extension Array {
	
	/// 総量を指定して、配列の先頭に要素を挿入する。
	mutating public func refreshInsert<ID>(
		id: KeyPath<Element, ID>,
		top item: Element,
		keep limit: Int,
	) where ID : Hashable {
		// 既に同じアイテムがあれば削除する
		removeAll{ $0[keyPath: id] == item[keyPath: id] }
		
		// アイテムを追加する
		insert(
			item,
			at: 0,
		)
		
		// 上限を超えていたら削除する
		while count > limit {
			removeLast()
		}
	}
	
	/// 総量を指定して、配列の先頭に要素を挿入する。
	mutating public func refreshInsert<ID>(
		id: KeyPath<Element, ID>,
		bottom item: Element,
		keep limit: Int,
	) where ID : Hashable {
		// 既に同じアイテムがあれば削除する
		removeAll{ $0[keyPath: id] == item[keyPath: id] }

		// アイテムを追加する
		append(
			item,
		)
		// 上限を超えていたら削除する
		while count > limit {
			removeFirst()
		}
	}
	
}


extension Array where Element : Identifiable {

	/// 総量を指定して、配列の先頭に要素を挿入する。
	@inlinable
	mutating public func refreshInsert(
		top item: Element,
		keep limit: Int,
	) {
		refreshInsert(id: \.id, top: item, keep: limit)
	}
	
	/// 総量を指定して、配列の先頭に要素を挿入する。
	@inlinable
	mutating public func refreshInsert(
		bottom item: Element,
		keep limit: Int,
	) {
		refreshInsert(id: \.id, bottom: item, keep: limit)
	}
	
}
