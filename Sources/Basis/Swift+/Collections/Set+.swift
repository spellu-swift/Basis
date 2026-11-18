

extension Set {

	/// トグル
	/// Bool.toggle() のような。
	public mutating func toggle(
		_ element: Element,
	) {
		if contains(element) {
			remove(element)
		}
		else {
			insert(element)
		}
	}
	
}



///
/// enum要素を扱えるメンバ関数
///
extension Set {
	
	@inlinable public func contains<Value>(
		_ member: Value,
	) -> Bool
	where Value : RawRepresentable<Element>
	{
		contains(member.rawValue)
	}
	
	@discardableResult
	@inlinable public mutating func insert<Value>(
		_ newMember: Value,
	) -> (inserted: Bool, memberAfterInsert: Element)
	where Value : RawRepresentable<Element>
	{
		insert(newMember.rawValue)
	}
	
	@discardableResult
	@inlinable public mutating func update<Value>(
		with newMember: Value,
	) -> Element?
	where Value : RawRepresentable<Element>
	{
		update(with: newMember.rawValue)
	}
	
	@discardableResult
	@inlinable public mutating func remove<Value>(
		_ member: Value,
	) -> Element?
	where Value : RawRepresentable<Element>
	{
		remove(member.rawValue)
	}
	
	public mutating func toggle<Value>(
		_ element: Value,
	)
	where Value : RawRepresentable<Element>
	{
		if contains(element.rawValue) {
			remove(element.rawValue)
		}
		else {
			insert(element.rawValue)
		}
	}
	
}

