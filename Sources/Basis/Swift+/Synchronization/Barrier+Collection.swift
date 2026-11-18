

extension Barrier where Value : Collection {
	
	
	public var isEmpty: Bool {
		resource.value.isEmpty
	}
	
	
	public var count: Int {
		resource.value.count
	}
	
	
}


extension Barrier where Value : RangeReplaceableCollection & Sendable {
	
	
	public convenience init(
	) {
		self.init(.init())
	}
	

	public convenience init(
		initialCapacity: Int
	) {
		var value: Value = .init()

		value.reserveCapacity(initialCapacity)

		self.init(value)
	}
	
	
	public func push(
		_ element: Value.Element
	) {
		write {
			$0.append(element)
			return .notifyAll
		}
	}
	
	
	public func pop(
	) -> Value.Element {
		read {
			$0.count > 0
			? .ok($0.removeFirst())
			: .wait
		}
	}
	
	
	public func pop(
		limit seconds: Double
	) -> Value.Element? {
		read(limit: seconds) {
			$0.count > 0
			? .ok($0.removeFirst())
			: .wait
		}
	}
	
	
}
