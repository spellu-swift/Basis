

/**
 * Identifiable配列
 */
extension Array where Element : Identifiable {
	
	
	public subscript(
		_ id: Element.ID?
	) -> Element? {
		get {
			first{ $0.id == id }
		}
		set {
			guard
				let index = firstIndex(where: {$0.id == id}),
				let newValue = newValue
			else { return }
			
			self[index] = newValue
		}
	}
	
	
}


extension Array where Element : Identifiable {
	
	
	@discardableResult
	public mutating func insert(
		_ items: Element...
	) -> [Element] {
		insert(items)
	}
	
	
	@discardableResult
	public mutating func insert(
		_ items: [Element]
	) -> [Element] {
		append(contentsOf: items)
		
		return items
	}
	
	
	@discardableResult
	public mutating func update(
		_ items: Element...
	) -> [Element] {
		update(items)
	}
	
	
	@discardableResult
	public mutating func update(
		_ items: [Element]
	) -> [Element] {
		for item in items {
			let index = firstIndex{ $0.id == item.id }
			if let index = index {
				self[index] = item
			}
		}
		
		return items
	}
	
	
	@discardableResult
	public mutating func remove(
		_ ids: Element.ID...
	) -> [Element.ID] {
		remove(ids)
	}
	
	
	@discardableResult
	public mutating func remove(
		_ ids: [Element.ID]
	) -> [Element.ID] {
		for id in ids {
			self.removeAll{ $0.id == id }
		}
		
		return ids
	}
	
	
}


