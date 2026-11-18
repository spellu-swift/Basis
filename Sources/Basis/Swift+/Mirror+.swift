

extension Mirror {

	
	public typealias Property<Value> = (name: String, value: Value)
	

	///
	/// SuperClassを含む全てのプロパティ
	///
	public var allChildren: [Child] {
		var result: [Child] = []
		
		var cursor: Mirror? = self

		while let mirror = cursor {
			result += mirror.children
			
			cursor = mirror.superclassMirror
		}
		
		return result
	}


	///
	/// SuperClassを含む全てのプロパティ
	///
	public func properties<Value>(
		_ type: Value.Type = Value.self
	)-> [Property<Value>] {
		allChildren.compactMap { label, value in
			guard
				let label = label,
				let value = value as? Value
			else { return nil }

			return Property(name: label, value: value)
		}
	}


}
