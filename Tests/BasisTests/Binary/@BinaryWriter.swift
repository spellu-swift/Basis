@testable import Basis


@Suite struct BinaryWriterTests {

	
	@Test
	func Bool_littleEndian() {
		let builder = BinaryWriter()
		builder.writeInt8(true)
		builder.writeInt8(false)

		#expect(builder.asBytes == [1, 0])
	}
	
	
	@Test
	func Int8_littleEndian() {
		let builder = BinaryWriter()
		builder.writeInt8(0x12)
		
		#expect(builder.asBytes == [0x12])
	}
	
	
	@Test
	func Int16_littleEndian() {
		let builder = BinaryWriter()
		builder.writeInt16(0x1234, endianness: .little)
		
		#expect(builder.asBytes == [0x34, 0x12])
	}
	
	
	@Test
	func test_Int16_bigEndian() {
		let builder = BinaryWriter()
		builder.writeInt16(0x1234, endianness: .big)
		
		#expect(builder.asBytes == [0x12, 0x34])
	}
	
	
	@Test
	func Int32_littleEndian() {
		let builder = BinaryWriter()
		builder.writeInt32(0x12345678, endianness: .little)
		
		#expect(builder.asBytes == [0x78, 0x56, 0x34, 0x12])
	}
	
	
	@Test
	func Int32_bigEndian() {
		let builder = BinaryWriter()
		builder.writeInt32(0x12345678, endianness: .big)
		
		#expect(builder.asBytes == [0x12, 0x34, 0x56, 0x78])
	}
	
	
	@Test
	func write_Bytes_1() {
		let builder = BinaryWriter()
		builder.writeBytes([1, 2])
		builder.writeBytes([3, 4, 5])

		#expect(builder.asBytes == [1, 2, 3, 4, 5])
	}
	
	
	@Test
	func typed_pointer_count_is_element_count() {
		let values: [UInt32] = [0x11223344, 0x55667788]
		let writer = BinaryWriter()

		values.withUnsafeBufferPointer {
			writer.write($0.baseAddress, count: $0.count)
		}
		writer.writeUInt8(0xFF)

		let expected = values.withUnsafeBytes { Array($0) } + [0xFF]

		#expect(writer.asBytes == expected)
		#expect(writer.offset == expected.count)
	}


	@Test
	func empty_writes() {
		let writer = BinaryWriter()
		let pointer: UnsafePointer<UInt32>? = nil

		writer.write(pointer, count: 0)
		writer.writeBytes([])
		writer.writeString("")

		#expect(writer.asBytes.isEmpty)
	}


	@Test
	func floating_point_writes() throws {
		let writer = BinaryWriter()
		writer.writeFloat32(1.25)
		writer.writeFloat64(-2.5)

		let reader = BinaryReader(writer.asBytes)

		#expect(writer.offset == 12)
		#expect(try reader.readFloat() == 1.25)
		#expect(try reader.readDouble() == -2.5)
		#expect(reader.remain == 0)
	}

	@Test
	func buffer_partial_writes() {
		let source = Buffer.allocate(capacity: 4)
		let bytes: UnsafeMutableBufferPointer<UInt8> = source.asMutableBufferPointer()
		bytes[0] = 1
		bytes[1] = 2
		bytes[2] = 3
		bytes[3] = 4

		let writer = BinaryWriter([9, 9, 9, 9, 9])
		writer.write(buffer: source, offset: 1, size: 2)
		writer.write(buffer: source, offset: 3)
		writer.write(buffer: source, offset: 4)

		#expect(writer.asBytes == [9, 9, 9, 9, 9, 2, 3, 4])
		#expect(writer.offset == 8)
	}

}

