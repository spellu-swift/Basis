

extension Optional {
	
	///
	/// 値を抽出する。
	/// nilの場合、errorを送出する。
	///
	@inlinable
	public func extract<E>(
		else error: E,
	) throws -> Wrapped
	where E : Error {
		switch self {
			case .none:
				throw error
				
			case .some(let value):
				return value
		}
	}

	///
	/// 値を抽出する。
	/// nilの場合、errorを送出する。
	///
	@inlinable
	public func extract<E>(
		else error: () -> E,
	) throws -> Wrapped
	where E : Error {
		switch self {
			case .none:
				throw error()
				
			case .some(let value):
				return value
		}
	}
	
	///
	/// 値を変換する。
	///
	@inlinable
	public func map<U>(
		_ transform: (Wrapped) -> U,
		else defaultValue: U,
	) -> U {
		switch self {
			case let .some(value):
				transform(value)
			case .none:
				defaultValue
		}
	}
	
	///
	/// 値を変換する。
	///
	@inlinable
	public func map<U>(
		_ transform: (Wrapped) -> U,
		else defaultValue: () -> U,
	) -> U {
		switch self {
			case let .some(value):
				transform(value)
			case .none:
				defaultValue()
		}
	}

	///
	/// 値を変換する。
	/// nilの場合、エラーを送出する。
	///
	@inlinable
	public func map<E, U>(
		_ transform: (Wrapped) -> U,
		else error: E,
	) throws -> U
	where E : Error {
		switch self {
			case let .some(value):
				transform(value)
			case .none:
				throw error
		}
	}
	
	///
	/// 値を変換する。
	/// nilの場合、エラーを送出する。
	///
	@inlinable
	public func map<E, U>(
		_ transform: (Wrapped) -> U,
		else error: () -> E,
	) throws -> U
	where E : Error {
		switch self {
			case let .some(value):
				transform(value)
			case .none:
				throw error()
		}
	}
	
	///
	/// 値を変換する。
	///
	@inlinable
	public func flatMap<U>(
		_ transform: (Wrapped) -> U?,
		else defaultValue: U,
	) -> U {
		switch self {
			case let .some(value):
				transform(value) ?? defaultValue
			case .none:
				defaultValue
		}
	}
	
	///
	/// 値を変換する。
	///
	@inlinable
	public func flatMap<U>(
		_ transform: (Wrapped) -> U?,
		else defaultValue: () -> U,
	) -> U {
		switch self {
			case let .some(value):
				transform(value) ?? defaultValue()
			case .none:
				defaultValue()
		}
	}
	
	///
	/// 値を変換する。
	/// nilの場合、エラーを送出する。
	///
	@inlinable
	public func flatMap<E, U>(
		_ transform: (Wrapped) -> U?,
		else error: E,
	) throws -> U
	where E : Error {
		switch self {
			case let .some(value):
				guard
					let value = transform(value)
				else { throw error }
				
				return value

			case .none:
				throw error
		}
	}
	
	///
	/// 値を変換する。
	/// nilの場合、エラーを送出する。
	///
	@inlinable
	public func flatMap<E, U>(
		_ transform: (Wrapped) -> U?,
		else error: () -> E,
	) throws -> U
	where E : Error {
		switch self {
			case let .some(value):
				guard
					let value = transform(value)
				else { throw error() }
				
				return value
				
			case .none:
				throw error()
		}
	}
	
	///
	/// 格納されている値を変更する。
	///
	@inlinable
	public mutating func modify(
		_ perform: (inout Wrapped) -> Void,
	) {
		if case .some(var value) = self {
			perform(&value)
			self = value
		}
	}
	
}
