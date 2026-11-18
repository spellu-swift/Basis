@testable import Basis


@Suite struct ClockTests {
	
	@Test func test() {
		#expect(
			ClockTime.EPOCH == ClockTime.clock(0, 0)
		)
	}
	
	@Test func duration() {
		let later: ClockTime = .clock(2, 100_000_000)
		let earlier: ClockTime = .clock(1)
		let duration: Duration = later.time(since: earlier)

		#expect(duration == .seconds(1) + .milliseconds(100))
	}
	
}

