import Libc


///
/// バイナリライター
/// さまざまなデータ型をバイナリに書き込める。
///
public class BinaryWriter {
	
	public static let ALIGNMENT_BITS: Int = 10
	
	public init(
		capacity count: Int = 1024,
	) {
		let capacity = (max(count, 1024) >> Self.ALIGNMENT_BITS) << Self.ALIGNMENT_BITS
		
		self.buffer = .allocate(capacity: capacity)
		self.offset = 0
	}
	
	public convenience init(
		_ bytes: [UInt8],
	) {
		self.init(capacity: bytes.count)
		
		writeBytes(bytes)
	}
	
	public private(set) var buffer: Buffer

	public private(set) var offset: Int
	
	func ensureCapacity(
		additional count: Int,
	) {
		if offset + count > buffer.count {
			var capacity: Int = buffer.count

			repeat {
				capacity *= 2
			}
			while capacity < offset + count

			buffer.reallocate(
				capacity: capacity
			)
		}
	}
	
	@inlinable
	public func writeInt8(
		_ bool: Bool,
	) {
		var value: Int8 = bool ? 1 : 0
		
		write(&value, count: 1)
	}
	
	@inlinable
	public func writeInt8(
		_ integer: any BinaryInteger,
	) {
		var value: Int8 = numericCast(integer)
		
		write(&value, count: 1)
	}
	
	@inlinable
	public func writeUInt8(
		_ value: any BinaryInteger,
	) {
		var value: UInt8 = numericCast(value)
		
		write(&value, count: 1)
	}
	
	@inlinable
	public func writeInt16(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: Int16

		switch endianness {
			case .big:
				value = Int16(bigEndian: numericCast(integer))
			case .little:
				value = Int16(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeUInt16(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: UInt16

		switch endianness {
			case .big:
				value = UInt16(bigEndian: numericCast(integer))
			case .little:
				value = UInt16(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeInt32(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: Int32
		
		switch endianness {
			case .big:
				value = Int32(bigEndian: numericCast(integer))
			case .little:
				value = Int32(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeUInt32(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: UInt32
		
		switch endianness {
			case .big:
				value = UInt32(bigEndian: numericCast(integer))
			case .little:
				value = UInt32(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeInt64(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: Int64
		
		switch endianness {
			case .big:
				value = Int64(bigEndian: numericCast(integer))
			case .little:
				value = Int64(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeUInt64(
		_ integer: any BinaryInteger,
		endianness: Endianness,
	) {
		var value: UInt64
		
		switch endianness {
			case .big:
				value = UInt64(bigEndian: numericCast(integer))
			case .little:
				value = UInt64(littleEndian: numericCast(integer))
		}

		write(&value, count: 1)
	}
	
	@inlinable
	public func writeFloat32(
		_ value: Float32,
	) {
		var value: Float32 = value
		
		write(&value, count: 1)
	}
	
	@inlinable
	public func writeFloat64(
		_ value: Float64,
	) {
		var value: Float64 = value
		
		write(&value, count: 1)
	}
	
	@inlinable
	public func writeBytes(
		_ bytes: [UInt8],
	) {
		bytes.withUnsafeBytes {
			write(
				$0
			)
		}
	}
	
	@inlinable
	public func writeBinary(
		_ binary: Binary,
	) {
		binary.asBytes.withUnsafeBytes {
			write(
				$0
			)
		}
	}
	
	@inlinable
	public func writeString(
		_ string: String,
	) {
		string.utf8.withContiguousStorageIfAvailable {
			write($0.baseAddress, count: $0.count)
		} ?? {
			var string = string
			string.withUTF8 {
				write($0.baseAddress, count: $0.count)
			}
		}()
	}

	@inlinable
	public func writeNullTerminatedString(
		_ string: String,
	) {
		string.withCString {
			write(
				$0,
				count: strlen($0)
			)
		}
		
		writeUInt8(0)
	}
	
	/// countはポインタが指す要素の数。
	public func write<T>(
		_ pointer: UnsafePointer<T>!,
		count: Int,
	) {
		precondition(count >= 0)
		guard count > 0 else { return }

		let size = count * MemoryLayout<T>.stride
		ensureCapacity(additional: size)
		
		memcpy(buffer.pointer + offset, pointer, size)
		offset += size
	}
	
	public func write(
		_ pointer: UnsafeRawPointer,
		bytes: Int,
	) {
		precondition(bytes >= 0)
		guard bytes > 0 else { return }

		ensureCapacity(additional: bytes)
		
		memcpy(buffer.pointer + offset, pointer, bytes)
		offset += bytes
	}
	
	public func write(
		_ other: UnsafeRawBufferPointer,
	) {
		guard !other.isEmpty else { return }

		ensureCapacity(additional: other.count)
		
		memcpy(buffer.pointer + offset, other.baseAddress!, other.count)
		offset += other.count
	}
	
	public func write(
		buffer other: Buffer,
		offset other_offset: Int = 0,
		size other_size: Int? = nil,
	) {
		precondition(other_offset >= 0 && other_offset <= other.count)

		let other_size = other_size ?? (other.count - other_offset)
		precondition(other_size >= 0 && other_size <= other.count - other_offset)
		guard other_size > 0 else { return }

		ensureCapacity(additional: other_size)

		memcpy(buffer.pointer + offset, other.pointer + other_offset, other_size)
		offset += other_size
	}
	
	@inlinable
	public var asBytes: [UInt8] {
		buffer.asBytes(0..<offset)
	}
	
	@inlinable
	public var asBinary: Binary {
		buffer.asBinary(0..<offset)
	}
	
}
