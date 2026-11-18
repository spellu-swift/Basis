@testable import Basis


struct ZonedDateTimeTest {
	
	@Test
	func epoch() {
		let epochTime: ZonedDateTime
		= .dateTime(1970, 1, 1, 0, 0, 0)

		let epochTimeSeconds = epochTime.epochSecond
		
		#expect(epochTimeSeconds == 0)
	}
	
}
