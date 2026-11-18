

///
/// Binaryリーダー
///
public class BinaryReader {
	
	public convenience init(
		_ data: Binary,
	) {
		self.init(data.asBytes[...])
	}
	
	public convenience init(
		_ bytes: [UInt8],
	) {
		self.init(bytes[...])
	}
	
	public init(
		_ bytes: ArraySlice<UInt8>,
	) {
		self.bytes = bytes
		self.readerIndex = 0
	}
	
	@usableFromInline var bytes: ArraySlice<UInt8>
	
	@usableFromInline package var readerIndex: Int
	
	public var asBytes: ArraySlice<UInt8> {
		bytes
	}
	
	public var count: Int {
		bytes.count
	}
	
	public var remain: Int {
		bytes.count - readerIndex
	}
	
}


extension BinaryReader {
	
	public typealias Slice = ArraySlice<UInt8>
	
	@inlinable
	public func fetch(
	) -> UInt8? {
		return try? getInteger(at: readerIndex, .big)
	}
	
	@inlinable
	public func fetch(
		count: Int,
	) -> ArraySlice<UInt8>? {
		return try? getBytes(at: readerIndex, count: count)
	}
	
	@inlinable
	@discardableResult
	public func skip(
		count: Int,
	) throws -> Self {
		guard checkRange(readerIndex, count)
		else { throw GeneralError.endOfStream(#function) }
		
		readerIndex += count
		
		return self
	}
	
	/// Read an integer off this `ByteBuffer`, move the reader index forward by the integer's byte size and return the result.
	///
	/// - parameters:
	///     - endianness: The endianness of the integer in this `ByteBuffer` (defaults to big endian).
	///     - as: the desired `FixedWidthInteger` type (optional parameter)
	/// - returns: An integer value deserialized from this `ByteBuffer` or `nil` if there aren't enough bytes readable.
	@inlinable
	public func readInteger<T: FixedWidthInteger>(
		_ endianness: Endianness,
		as: T.Type = T.self,
	) throws -> T {
		let result = try getInteger(
			at: self.readerIndex,
			endianness,
			as: T.self
		)
		
		readerIndex += MemoryLayout<T>.size
		
		return result
	}
	
	@inlinable
	public func readInt8(
	) throws -> Int8 {
		let result: Int8 = Int8(bitPattern: try getByte(at: readerIndex))
		
		readerIndex += 1
		
		return result
	}
	
	@inlinable
	public func readInt16(
		_ endianness: Endianness,
	) throws -> Int16 {
		try readInteger(endianness)
	}
	
	@inlinable
	public func readInt32(
		_ endianness: Endianness,
	) throws -> Int32 {
		try readInteger(endianness)
	}
	
	@inlinable
	public func readInt64(
		_ endianness: Endianness,
	) throws -> Int64 {
		try readInteger(endianness)
	}

	@inlinable
	public func readUInt8(
	) throws -> UInt8 {
		let result: UInt8 = try getByte(at: readerIndex)
		
		readerIndex += MemoryLayout<UInt8>.size
		
		return result
	}
	
	@inlinable
	public func readUInt16(
		_ endianness: Endianness,
	) throws -> UInt16 {
		try readInteger(endianness)
	}
	
	@inlinable
	public func readUInt32(
		_ endianness: Endianness,
	) throws -> UInt32 {
		try readInteger(endianness)
	}
	
	@inlinable
	public func readUInt64(
		_ endianness: Endianness,
	) throws -> UInt64 {
		try readInteger(endianness)
	}
	
	public func readFloat(
	) throws -> Float {
		let bytes: ArraySlice<UInt8> = try readBytes(count: MemoryLayout<Float>.size)
		
		var value: Float = 0
		
		Swift.withUnsafeMutableBytes(of: &value) { buffer in
			buffer.copyBytes(from: bytes)
		}
		
		return value
	}
	
	public func readDouble(
	) throws -> Double {
		let bytes: ArraySlice<UInt8> = try readBytes(count: MemoryLayout<Double>.size)
		
		var value: Double = 0
		
		Swift.withUnsafeMutableBytes(of: &value) { buffer in
			buffer.copyBytes(from: bytes)
		}
		
		return value
	}
	
	@inlinable
	public func readBytes(
		count: Int,
	) throws -> ArraySlice<UInt8> {
		let result = try getBytes(at: readerIndex, count: count)
		
		readerIndex += count
		
		return result
	}
	
	/// 文字列を読む
	@inlinable
	public func readString(
		count: Int,
	) throws -> String {
		let result: ArraySlice<UInt8> = try getBytes(at: readerIndex, count: count)
		
		readerIndex += count
		
		return String(decoding: result, as: UTF8.self)
	}
	
	/// NULL文字終端のバイト配列を読む
	@inlinable
	public func readBytes(
		terminator: UInt8 = 0x00,
	) throws -> ArraySlice<UInt8> {
		let result = try getBytes(at: readerIndex, until: terminator)
		
		readerIndex += result.count + 1
		
		return result
	}
	
	/// NULL文字終端の文字列を読む
	@inlinable
	public func readString(
		terminator: UInt8 = 0x00,
	) throws -> String {
		let result = try getBytes(at: readerIndex, until: terminator)
		
		readerIndex += result.count + 1
		
		return String(decoding: result, as: UTF8.self)
	}
	
}


extension BinaryReader {
	
	@inlinable
	public func getByte(
		at index: Int,
	) throws -> UInt8 {
		guard checkRange(index, 1)
		else { throw GeneralError.endOfStream(#function) }

		return bytes[bytes.startIndex + index]
	}
	
	@inlinable
	public func getBytes(
		at index: Int,
		count: Int,
	) throws -> ArraySlice<UInt8> {
		guard checkRange(index, count)
		else { throw GeneralError.endOfStream(#function) }

		return bytes[bytes.startIndex + index ..< bytes.startIndex + index + count]
	}
	
	@inlinable
	public func getBytes(
		at index: Int,
		until terminator: UInt8,
	) throws -> ArraySlice<UInt8> {
		guard checkRange(index, 0)
		else { throw GeneralError.endOfStream(#function) }

		let startIndex = bytes.startIndex + index
		guard let endIndex = bytes[startIndex...].firstIndex(where: { $0 == terminator })
		else { throw GeneralError.endOfStream(#function) }

		return bytes[startIndex..<endIndex]
	}
	
	/// Get the integer at `index` from this `ByteBuffer`. Does not move the reader index.
	/// The selected bytes must be readable or else `nil` will be returned.
	///
	/// - parameters:
	///     - index: The starting index of the bytes for the integer into the `ByteBuffer`.
	///     - endianness: The endianness of the integer in this `ByteBuffer` (defaults to big endian).
	///     - as: the desired `FixedWidthInteger` type (optional parameter)
	/// - returns: An integer value deserialized from this `ByteBuffer` or `nil` if the bytes of interest are not
	///            readable.
	@inlinable
	public func getInteger<T: FixedWidthInteger>(
		at index: Int,
		_ endianness: Endianness,
		as: T.Type = T.self,
	) throws -> T {
		let start: Int = bytes.startIndex
		let size: Int = MemoryLayout<T>.size
		
		guard checkRange(index, size)
		else { throw GeneralError.endOfStream(#function) }

		if T.self == UInt8.self {
			return bytes[start + index] as! T
		}
		
		var value: T = 0
		
		Swift.withUnsafeMutableBytes(of: &value) { buffer in
			buffer.copyBytes(from: bytes[(start + index)..<(start + index + size)])
		}
		
		return asEndianness(value: value, endianness: endianness)
	}
	
	@usableFromInline
	func asEndianness<T: FixedWidthInteger> (value: T, endianness: Endianness) -> T {
		switch endianness {
			case .little:
				return value.littleEndian
			case .big:
				return value.bigEndian
		}
	}
	
	@inlinable
	func checkRange(
		_ index: Int,
		_ length: Int,
	) -> Bool {
		precondition(index >= 0 && length >= 0)
		
		return index <= bytes.count && length <= bytes.count - index
	}

}
