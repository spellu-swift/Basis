

@Orderable
public struct Binary : Sendable {

	public static let empty: Binary = Binary()
	

	@inlinable
	public init(
		_ slice: Slice<Binary>,
	) {
		self._raw = slice.asBytes
	}
	
	@inlinable
	public init(
		_ bytes: [UInt8],
	) {
		self._raw = bytes
	}

	@inlinable
	public init(
		_ bytes: UnsafeRawBufferPointer,
	) {
		self._raw = [UInt8](bytes)
	}
	
	@inlinable
	public init(
		bytes: UnsafeRawPointer,
		count: Int,
	) {
		self._raw = [UInt8](
			UnsafeRawBufferPointer(start: bytes, count: count)
		)
	}

	public init<Tuple>(
		tuple: Tuple,
	) {
		self = Swift.withUnsafeBytes(of: tuple) {
			Binary(bytes: $0.baseAddress!, count: $0.count)
		}
	}

	@inlinable
	public init(
		capacity: Int,
		initializer: (_ buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int,
	) rethrows {
		self._raw = try [UInt8](unsafeUninitializedCapacity: capacity) { buffer, count in
			count = try initializer(buffer)
		}
	}
	
	@inlinable
	public func withUnsafeBytes<R>(
		_ body: (UnsafeRawBufferPointer) throws -> R,
	) rethrows -> R {
		try _raw.withUnsafeBytes(body)
	}

	@inlinable
	public mutating func withUnsafeMutableBytes<R>(
		_ body: (UnsafeMutableRawBufferPointer) throws -> R,
	) rethrows -> R {
		try _raw.withUnsafeMutableBytes(body)
	}

	@usableFromInline
	package var _raw: [UInt8]
	
}


extension Binary {

	@inlinable
	public var asBytes: [UInt8] {
		_raw
	}
	
	@inlinable
	public var asString: String {
		String(decoding: _raw, as: UTF8.self)
	}
	
}


extension Binary : ExpressibleByArrayLiteral {

	public typealias ArrayLiteralElement = UInt8

	@inlinable
	public init(
		arrayLiteral elements: ArrayLiteralElement...
	) {
		self._raw = elements
	}

}


extension Binary : ExpressibleByStringLiteral {

	@inlinable
	public init(
		stringLiteral value: StringLiteralType
	) {
		self._raw = value.asBytes
	}

}


//@inlinable
//public func == (
//	lhs: Binary?,
//	rhs: Slice<Binary>
//) -> Bool {
//	lhs?[...] == rhs
//}


@inlinable
public func == (
	lhs: Binary?,
	rhs: [UInt8]
) -> Bool {
	lhs?._raw == rhs
}


@inlinable
public func == (
	lhs: Binary?,
	rhs: ArraySlice<UInt8>
) -> Bool {
	lhs?._raw[...] == rhs
}


extension Binary : Hashable {}


extension Binary : RandomAccessCollection, MutableCollection {

	public var count: Int {
		_raw.count
	}
	
	public var indices: Range<Int> {
		_raw.indices
	}

	public var startIndex: Int {
		0
	}
	
	public var endIndex: Int {
		_raw.count
	}
	
	public subscript(
		position: Int,
	) -> UInt8 {
		get {
			_raw[position]
		}
		set {
			_raw[position] = newValue
		}
	}

	public func get(
		at index: Int
	) -> UInt8? {
		_raw.indices.contains(index) ? _raw[index] : nil
	}

}


extension Binary : Sequence {

	public typealias Element = UInt8

	public typealias Iterator = Array<UInt8>.Iterator

	public __consuming func makeIterator() -> Array<UInt8>.Iterator {
		_raw.makeIterator()
	}
	
}



