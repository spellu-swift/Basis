

extension Equatable {
	
	/// 渡された値が元の値と異なる場合に更新する。
	@inlinable
	public mutating func modify(
		_ value: Self,
	) {
		if self != value {
			self = value
		}
	}
	
	/// 渡された値が元の値と異なる場合に更新し、クロージャを呼び出す。
	@inlinable
	public mutating func modify(
		_ value: Self,
		perform: @escaping (Self) -> Void,
	) {
		if self != value {
			self = value
			
			perform(value)
		}
	}
	
}
