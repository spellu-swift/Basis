@testable import Basis


struct LocalDateTimeTest {

	@Test
	func now() {
		#print(LocalDateTime.now)
		#print(LocalDateTime.now(zone: .utc))
		#print(ZonedDateTime.now)
		#print(ZonedDateTime.now.epochSecond)
	}

	@Test
	func epoch() {
		let epochTime: LocalDateTime = .dateTime(1970, 1, 1, 0, 0, 0)
		
		let epochTimeSeconds = epochTime.epochSecond(zone: .system)
		
		#expect(epochTimeSeconds == -32400)
	}
	
}
