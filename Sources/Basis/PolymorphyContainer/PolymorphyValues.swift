

/// extension PolymorphyValues の中で使う
@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro PolymorphyEntry()
= #externalMacro(
	module: "BasisMacros",
	type: "PolymorphyEntryMacro",
)


public protocol PolymorphyKey {
	
	/// The associated type representing the type of the environment key's
	/// value.
	associatedtype Value
	
	/// The default value for the environment key.
	static var defaultValue: Self.Value { get }
	
}


extension PolymorphyKey {
	
	public static var id: String {
		String(describing: Self.self)
	}
	
}


public final class PolymorphyValues {
	
	public init(
	) {
		self.chain = nil
	}
	
	public init(
		chain: PolymorphyValues,
	) {
		self.chain = chain
	}
	
	private let chain: PolymorphyValues?
	
	private var storage: [String : Any] = [:]
	
	public subscript<Key : PolymorphyKey>(
		_ key: Key.Type,
	) -> Key.Value {
		get { (storage[key.id] as? Key.Value) ?? chain?[key] ?? Key.defaultValue }
		set { storage[key.id] = newValue }
	}
	
}


extension PolymorphyValues {
	
	@PolymorphyEntry public var now: () -> ClockTime = { .now }

	@PolymorphyEntry public var uuid: () -> UUID = { .new }
	
}


