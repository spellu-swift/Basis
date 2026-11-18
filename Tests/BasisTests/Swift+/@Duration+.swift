@testable import Basis


@Suite struct DurationExtensionTests {

	@Test(arguments: [
		(Duration.zero, 0.0),
		(.seconds(1), 1.0),
		(.milliseconds(500), 0.5),
		(.milliseconds(1_500), 1.5),
		(.nanoseconds(1), 0.000_000_001),
		(.milliseconds(-1_500), -1.5),
		(.seconds(-1), -1.0),
	])
	func asDoubleは秒数を返す(
		duration: Duration,
		expected: Double,
	) {
		#expect(duration.asDouble == expected)
	}

}
