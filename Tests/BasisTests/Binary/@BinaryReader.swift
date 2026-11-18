@testable import Basis


@Suite struct BinaryReaderTests {

	@Test
	func terminated_reads_from_slice() throws {
		let bytes: [UInt8] = [99, 65, 0, 66, 0, 67]
		let reader = BinaryReader(bytes[1...])

		#expect(try reader.readString() == "A")
		#expect(try Array(reader.readBytes()) == [66])
		#expect(try reader.readUInt8() == 67)
		#expect(reader.remain == 0)

		#expect(throws: GeneralError.self) {
			try reader.readString()
		}
	}


	@Test
	func missing_terminator_does_not_advance() throws {
		let bytes: [UInt8] = [99, 65, 66]
		let reader = BinaryReader(bytes[1...])

		#expect(throws: GeneralError.self) {
			try reader.readString()
		}
		#expect(reader.remain == 2)
		#expect(try reader.readString(count: 2) == "AB")
	}


	@Test
	func terminated_read_out_of_bounds() {
		let reader = BinaryReader([UInt8]())

		#expect(throws: GeneralError.self) {
			try reader.getBytes(at: 1, until: 0)
		}
		#expect(throws: GeneralError.self) {
			try reader.getBytes(at: 0, count: Int.max)
		}
	}
}
