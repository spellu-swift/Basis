@testable import Basis


@Test
func clock_time_duration_signed_arithmetic() {
	let base: ClockTime = .clock(0, 100_000_000)
	let duration: Duration = .milliseconds(200)

	#expect(base + duration == .clock(0, 300_000_000))
	#expect(base - duration == .clock(-1, 900_000_000))
	#expect(base.plus(.zero - duration) == base - duration)
	#expect(base.minus(.zero - duration) == base + duration)
	#expect((base - duration) + duration == base)
	#expect((base + duration) - base == duration)
	#expect(base - (base + duration) == .zero - duration)
}


@Test
func clock_time_duration_discards_subnanosecond_fraction() {
	let base: ClockTime = .clock(0)
	let halfNanosecond: Duration = .init(secondsComponent: 0, attosecondsComponent: 500_000_000)
	let oneAndHalf: Duration = .nanoseconds(1) + halfNanosecond

	#expect(base + halfNanosecond == base)
	#expect(base - halfNanosecond == base)
	#expect(base + oneAndHalf == .clock(0, 1))
	#expect(base - oneAndHalf == .clock(-1, 999_999_999))
}


@Test
func clock_time_duration_preserves_large_integer_precision() {
	let difference: Duration = ClockTime.MAX - ClockTime.MIN
	let seconds = ClockTime.MAX.seconds - ClockTime.MIN.seconds

	#expect(difference == .seconds(seconds) + .nanoseconds(999_999_999))
	#expect(ClockTime.MIN + difference == ClockTime.MAX)
	#expect(ClockTime.MAX - difference == ClockTime.MIN)
}


@Test
func clock_time_duration_retains_double_second_operators() {
	let base: ClockTime = .clock(0, 100_000_000)

	#expect(base + 1.5 == .clock(1, 600_000_000))
	#expect(base - 1.5 == .clock(-2, 600_000_000))
}
