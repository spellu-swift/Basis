

///
/// データキャッシュ
///
/// getメソッドは、キーに対する値が存在しない場合、デフォルト値を設定する。
///
public struct Cache<Key : Hashable, Value> {
	
	public init() {
		self.data = [:]
	}
	
	var data: [Key : Value]
	
	/// keyに対応するキー値を取得する。
	/// 値が存在しなければdefaultを呼び出し、その返り値をキー値として設定し、キー値を返す。
	public mutating func get(
		_ key: Key,
	) -> Value where Value : Default {
		data.insertIfEmpty(key: key, value: .default)
	}
	
	/// keyに対応するキー値を取得する。
	/// 値が存在しなければdefaultをキー値として設定し、キー値を返す。
	public mutating func get(
		_ key: Key,
		default value: Value,
	) -> Value {
		data.insertIfEmpty(key: key, value: value)
	}
	
	/// keyに対応するキー値を取得する。
	/// 値が存在しなければdefaultを呼び出し、その返り値をキー値として設定し、キー値を返す。
	public mutating func get(
		_ key: Key,
		default value: @escaping () throws -> Value,
	) rethrows -> Value {
		try data.insertIfEmpty(key: key, value: value)
	}
	
	/// keyに対応するキー値を設定する。
	public mutating func set(
		_ key: Key,
		value: Value,
	) {
		data[key] = value
	}
	
	/// サブスクリプト
	public subscript(
		_ key: Key,
	) -> Value where Value : Default {
		mutating get {
			get(key, default: .default)
		}
		set {
			set(key, value: newValue)
		}
	}
	
	/// サブスクリプト
	public subscript(
		_ key: Key,
	) -> Value {
		get {
			let value = data[key]
			
			precondition(value != nil, "Cache key:'\(key)' is not found.")
			
			return value!
		}
		set {
			set(key, value: newValue)
		}
	}
	
	/// サブスクリプト
	public subscript(
		_ key: Key,
		default value: Value,
	) -> Value {
		mutating get {
			get(key, default: value)
		}
	}
	
	/// サブスクリプト
	public subscript(
		_ key: Key,
		default value: @escaping () -> Value,
	) -> Value {
		mutating get {
			get(key, default: value)
		}
	}

	/// サブスクリプト
	public subscript(
		_ key: Key,
		default value: @escaping () throws -> Value,
	) -> Value {
		mutating get throws {
			try get(key, default: value)
		}
	}

	/// 全キー
	public var keys: Dictionary<Key, Value>.Keys {
		data.keys
	}
	
	/// 全値
	public var values: Dictionary<Key, Value>.Values {
		data.values
	}

	/// クリア
	public mutating func clear(
		_ key: Key,
	) {
		data.removeValue(forKey: key)
	}
	
	/// クリア
	public mutating func clear() {
		data.removeAll()
	}
	
}


extension Cache : Sequence {
	
	public func makeIterator() -> DictionaryIterator<Key, Value> {
		data.makeIterator()
	}
	
}


extension Cache : Sendable where Key : Sendable, Value : Sendable {}


extension Cache : Default {

	public static var `default`: Self { .init() }
	
}


extension Cache : ExpressibleByDictionaryLiteral {
	
	public init(
		dictionaryLiteral elements: (Key, Value)...,
	) {
		self.data = .init(elements)
	}
	
}
