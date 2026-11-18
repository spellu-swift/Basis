

extension Bool {
	
	public static func |=(
		left: inout Bool,
		right: Bool
	) {
		if right {
			left = true
		}
	}
	
	public static func &=(
		left: inout Bool,
		right: Bool
	) {
		if left && right {
			left = true
		}
	}
	
}
