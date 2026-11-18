@testable import Basis


@Test
func clockTime_fractional_seconds_are_normalized() {
	let examples: [(Double, ClockTime)] = [
		(-1.75, .clock(-2, 250_000_000)),
		(-0.5, .clock(-1, 500_000_000)),
		(-0.25, .clock(-1, 750_000_000)),
		(-1, .clock(-1)),
		(0, .EPOCH),
		(0.5, .clock(0, 500_000_000)),
		(1.75, .clock(1, 750_000_000)),
	]

	for (seconds, expected) in examples {
		let clock: ClockTime = .clock(seconds)
		#expect(clock == expected)
		#expect(clock.nano >= 0 && clock.nano < NANOS_PER_SECOND)
		#expect(clock.asLocalDateTime(zone: .utc) == expected.asLocalDateTime(zone: .utc))
	}
}
