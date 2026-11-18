

public protocol DynamicWrapper {
	
	associatedtype RawValue
	
	var rawValue: RawValue { get set }
	
	subscript<T>(
		dynamicMember keyPath: KeyPath<RawValue, T>
	) -> T { get }
	
	subscript<T>(
		dynamicMember keyPath: WritableKeyPath<RawValue, T>
	) -> T { get set }
	
}


extension DynamicWrapper {

	public subscript<T>(
		dynamicMember keyPath: KeyPath<RawValue, T>
	) -> T {
		rawValue[keyPath: keyPath]
	}

	public subscript<T>(
		dynamicMember keyPath: WritableKeyPath<RawValue, T>
	) -> T {
		get {
			return rawValue[keyPath: keyPath]
		}
		
		set {
			rawValue[keyPath: keyPath] = newValue
		}
	}
	
}


