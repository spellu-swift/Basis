@testable import Basis


typealias UUID = Basis.UUID


@Suite struct UUIDTests {
	
	
	@Test
	func initByUUID(
	) {
		let uuid: uuid_t = (
			0x01, 0x23, 0x45, 0x67,
			0x89, 0xAB, 0xCD, 0xEF,
			0x01, 0x23, 0x45, 0x67,
			0x89, 0xAB, 0xCD, 0xEF
		)

		#expect(
			UUID(uuid).description
			==
			"01234567-89AB-CDEF-0123-456789ABCDEF"
		)

		
		func equals(_ lhs: uuid_t, _ rhs: uuid_t) -> Bool {
			lhs.0 == rhs.0 &&
			lhs.1 == rhs.1 &&
			lhs.2 == rhs.2 &&
			lhs.3 == rhs.3 &&
			lhs.4 == rhs.4 &&
			lhs.5 == rhs.5 &&
			lhs.6 == rhs.6 &&
			lhs.7 == rhs.7 &&
			lhs.8 == rhs.8 &&
			lhs.9 == rhs.9 &&
			lhs.10 == rhs.10 &&
			lhs.11 == rhs.11 &&
			lhs.12 == rhs.12 &&
			lhs.13 == rhs.13 &&
			lhs.14 == rhs.14 &&
			lhs.15 == rhs.15
		}
		
		#expect(
			equals(UUID(uuid).uuid, uuid)
		)
		
	}
	
	
	@Test
	func initByString(
	) {
		#expect(
			UUID("01230123-4545-6767-8989-ABCDEFABCDEF")?.description
			==
			"01230123-4545-6767-8989-ABCDEFABCDEF"
		)

		#expect(
			UUID(.uuid, "01230123-4545-6767-8989-ABCDEFABCDEF")?.asString(.uuid)
			==
			"01230123-4545-6767-8989-ABCDEFABCDEF"
		)

		#expect(
			UUID(.hex, "01230123454567678989ABCDEFABCDEF")?.asString(.hex)
			==
			"01230123454567678989ABCDEFABCDEF"
		)
	}


	@Test
	func newはバージョン4の乱数UUIDを作る(
	) {
		let uuid: uuid_t = UUID.new.uuid

		#expect(uuid.6 & 0xF0 == 0x40)
		#expect(uuid.8 & 0xC0 == 0x80)
		#expect(UUID.new.description != UUID.new.description)
	}


}

