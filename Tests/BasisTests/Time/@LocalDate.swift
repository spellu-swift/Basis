@testable import Basis


@Test
func localDate_known_epoch_days() {
	let examples: [(LocalDate, Int)] = [
		(.date(0, 1, 1), -719528),
		(.date(0, 2, 29), -719469),
		(.date(1, 1, 1), -719162),
		(.date(1969, 12, 31), -1),
		(.date(1970, 1, 1), 0),
		(.date(2000, 2, 29), 11016),
		(.date(9999, 12, 31), 2932896),
	]

	for (date, epochDay) in examples {
		#expect(date.epochDay == epochDay)
		#expect(LocalDate.date(epochDay: epochDay) == date)
	}
}


@Test
func localDate_complete_gregorian_cycle() {
	// 日数変換を使わず年月日を順に進め、400年周期の全日付を検証する。
	var epochDay = -719162
	let monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

	for year in 1...400 {
		let leapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)

		for month in 1...12 {
			let length = monthLengths[month - 1] + (month == 2 && leapYear ? 1 : 0)

			for day in 1...length {
				let date: LocalDate = .date(year, month, day)
				#expect(date.epochDay == epochDay)
				#expect(LocalDate.date(epochDay: epochDay) == date)

				// 同じ月日は400年前・800年前でも同じ周期内の位置になる。
				for cycles in [1, 2] {
					let earlier: LocalDate = .date(year - cycles * 400, month, day)
					let earlierDay = epochDay - cycles * 146097
					#expect(earlier.epochDay == earlierDay)
					#expect(LocalDate.date(epochDay: earlierDay) == earlier)
				}

				epochDay += 1
			}
		}
	}

	#expect(epochDay == -573065)
}


@Test
func localDate_extreme_years() {
	for date in [LocalDate.MIN, LocalDate.MAX] {
		#expect(LocalDate.date(epochDay: date.epochDay) == date)
	}

	#expect(LocalDate.date(epochDay: LocalDate.MIN.epochDay + 1) == .date(Year.MIN_VALUE, 1, 2))
	#expect(LocalDate.date(epochDay: LocalDate.MAX.epochDay - 1) == .date(Year.MAX_VALUE, 12, 30))
}
