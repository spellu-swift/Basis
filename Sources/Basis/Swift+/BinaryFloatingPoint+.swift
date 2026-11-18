

extension BinaryFloatingPoint {

	/// 整数部と小数部に分割する。
	@inlinable
	public var splitted: (Int, Self) {
		(
			Int(self),
			self.truncatingRemainder(dividingBy: 1.0)
		)
	}
	
	/// 整数値に変換する。
	@inlinable
	public var asInt: Int {
		Int(self)
	}

	/// 装飾なしで浮動小数を文字列にする。
	@inlinable
	public var asString: String {
		String(describing: self)
	}
	
}
