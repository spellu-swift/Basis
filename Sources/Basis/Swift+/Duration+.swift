extension Swift.Duration {

	/// 秒数を表す浮動小数点数。
	@inlinable
	public var asDouble: Double {
		let (seconds, attoseconds) = components

		return Double(seconds) + Double(attoseconds) / 1e18
	}
	
}
