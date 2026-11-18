

extension Array where Element : Equatable {
	
	
	public mutating func insert(
		_ items: Element...
	) {
		append(contentsOf: items)
	}
	
	
	public mutating func remove(
		_ items: Element...
	) {
		for item in items {
			removeAll{ $0 == item }
		}
	}
	
	
}
