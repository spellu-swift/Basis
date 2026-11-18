

extension BinaryInteger {
	
	/// 浮動小数値に変換する。
	@inlinable
	public var asDouble: Double {
		Double(self)
	}
	
	/// 装飾なしで整数を文字列にする。
	@inlinable
	public var asString: String {
		String(self, radix: 10)
	}

}


