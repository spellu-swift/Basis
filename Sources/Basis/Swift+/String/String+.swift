

extension String {
	
	/// 空文字列
	public static let empty: String = ""
		
	/// 型名
	public init(
		typeOf value: Any?
	) {
		if
			let value
		{
			self = String(describing: type(of: value))
		} else {
			self = "nil"
		}
	}
	
	/// C文字列（Null-Terminatedとは限らない）
	@inlinable
	public init(
		cString bytes: UnsafePointer<CChar>,
		count: any BinaryInteger
	) {
		self.init(
			decoding: UnsafeRawBufferPointer(
				start: bytes,
				count: Int(count)
			)
			.bindMemory(to: UInt8.self),
			as: UTF8.self
		)
	}
		
	/// C文字列（Null-Terminatedとは限らない）
	@inlinable
	public init(
		cString bytes: UnsafePointer<UInt8>,
		count: any BinaryInteger
	) {
		self.init(
			decoding: UnsafeBufferPointer(
				start: bytes,
				count: Int(count)
			),
			as: UTF8.self
		)
	}
		
	/// バッファを用意し、C-APIに渡して文字列を取得することを想定している。
	@inlinable
	public init(
		capacity: Int,
		initializer: (_ buffer: UnsafeMutableBufferPointer<CChar>) throws -> Int
	) rethrows {
		try self.init(unsafeUninitializedCapacity: capacity) {
			try $0.withMemoryRebound(to: CChar.self) { buffer in
				try initializer(buffer)
			}
		}
	}
		
}


extension String {
	
	/// 先頭落とし
	@inlinable
	public func drop(
		first: Int
	) -> Substring {
		return dropFirst(first)
	}
	
	/// 末尾落とし
	@inlinable
	public func drop(
		last: Int
	) -> Substring {
		return dropLast(last)
	}
		
}


