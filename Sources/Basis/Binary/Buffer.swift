import Libc


///
/// CメモリAPIを使ったバッファ
///
public final class Buffer {
	
	@inlinable
	public static func allocate(
		capacity: Int
	) -> Buffer {
		Buffer(
			pointer: calloc(1, capacity),
			count: capacity
		)
	}
	
	@inlinable
	public static func allocate<T>(
		type: T.Type = T.self
	) -> Buffer {
		allocate(
			capacity: MemoryLayout<T>.stride
		)
	}
	
	@usableFromInline
	init(
		pointer: UnsafeMutableRawPointer,
		count: Int
	) {
		precondition(count >= 0)

		self.pointer = pointer
		self.count = count
	}
	
	deinit {
		free(pointer)
	}
	
	public private(set) var pointer: UnsafeMutableRawPointer
	public private(set) var count: Int
	
	public func reallocate(
		capacity count: Int
	) {
		if count > self.count {
			self.pointer = realloc(pointer, count)
			self.count = count
		}
	}
	
	@inlinable
	public func asBufferPointer<T>(
	) -> UnsafeBufferPointer<T> {
		.init(
			start: pointer.assumingMemoryBound(to: T.self),
			count: count / MemoryLayout<T>.stride
		)
	}
	
	@inlinable
	public func asMutableBufferPointer<T>(
	) -> UnsafeMutableBufferPointer<T> {
		.init(
			start: pointer.assumingMemoryBound(to: T.self),
			count: count / MemoryLayout<T>.stride
		)
	}
	
	@inlinable
	public var asRawBufferPointer: UnsafeRawBufferPointer {
		.init(
			start: pointer,
			count: count
		)
	}
	
	@inlinable
	public var asMutableRawBufferPointer: UnsafeMutableRawBufferPointer {
		.init(
			start: pointer,
			count: count
		)
	}

	@inlinable
	public var asBytes: [UInt8] {
		.init(asRawBufferPointer)
	}
	
	@inlinable
	public var asBinary: Binary {
		.init(.init(asRawBufferPointer))
	}
	
	@inlinable
	public func asBytes(
		_ range: Range<Int>
	) -> [UInt8] {
		precondition(range.lowerBound >= 0 && range.upperBound <= count)

		return .init(
			UnsafeRawBufferPointer(
				start: pointer + range.lowerBound,
				count: range.count
			)
		)
	}
	
	@inlinable
	public func asBinary(
		_ range: Range<Int>
	) -> Binary {
		precondition(range.lowerBound >= 0 && range.upperBound <= count)
		
		return .init(
			UnsafeRawBufferPointer(
				start: pointer + range.lowerBound,
				count: range.count
			)
		)
	}
	
}
