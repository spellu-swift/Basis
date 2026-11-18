@testable import Basis


@Suite struct BufferTests {

	@Test
	func typed_pointer_count() {
		let buffer = Buffer.allocate(capacity: 9)
		let immutable: UnsafeBufferPointer<UInt32> = buffer.asBufferPointer()
		let mutable: UnsafeMutableBufferPointer<UInt32> = buffer.asMutableBufferPointer()

		#expect(immutable.count == 2)
		#expect(mutable.count == 2)

		mutable[0] = 0x11223344
		mutable[1] = 0x55667788

		#expect(Array(immutable) == [0x11223344, 0x55667788])
		#expect(buffer.asBytes.count == 9)
	}


	@Test
	func allocation_for_padded_type() {
		struct Padded {
			var integer: UInt64
			var byte: UInt8
		}

		let buffer = Buffer.allocate(type: Padded.self)
		let pointer: UnsafeBufferPointer<Padded> = buffer.asBufferPointer()

		#expect(buffer.count == MemoryLayout<Padded>.stride)
		#expect(pointer.count == 1)
	}

	@Test
	func slices_at_boundaries() {
		let buffer = Buffer.allocate(capacity: 4)
		let bytes: UnsafeMutableBufferPointer<UInt8> = buffer.asMutableBufferPointer()
		bytes[0] = 1
		bytes[1] = 2
		bytes[2] = 3
		bytes[3] = 4

		#expect(buffer.asBytes(0..<4) == [1, 2, 3, 4])
		#expect(buffer.asBytes(3..<4) == [4])
		#expect(buffer.asBytes(4..<4).isEmpty)
		#expect(buffer.asBinary(3..<4).asBytes == [4])
		#expect(buffer.asBinary(4..<4).asBytes.isEmpty)
	}
}
