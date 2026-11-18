@testable import BigDecimal
import UnitTesting


@Suite struct BigDecimal生成テスト {

	// MARK: 非スケール値とスケール

	@Test func 非スケール値とスケールから作れる() {
		let value: BigDecimal = .init(unscaledValue: 150, scale: 2)

		#expect(value.unscaledValue == 150)
		#expect(value.scale == 2)
		#expect(value.description == "1.50")
	}

	@Test func 負のスケールは十の冪を掛ける() {
		let value: BigDecimal = .init(unscaledValue: 123, scale: -2)

		#expect(value == 12300)
		#expect(value.description == "1.23E+4")
	}

	// MARK: 整数

	@Test func 整数リテラルから作るとスケール0() {
		let small: BigDecimal = 42
		let large: BigDecimal = -123456789012345678901234567890

		#expect(small.isIdentical(to: .init(unscaledValue: 42, scale: 0)))
		#expect(large.description == "-123456789012345678901234567890")
		#expect(large.scale == 0)
	}

	@Test func 整数型から作るとスケール0() {
		#expect(BigDecimal(Int.min).description == "-9223372036854775808")
		#expect(BigDecimal(UInt.max).description == "18446744073709551615")
		#expect(BigDecimal(BigInt(1) << 100).scale == 0)
		#expect(BigDecimal(exactly: Int8(-5))?.description == "-5")
	}

	// MARK: 文字列

	@Test func 文字列のスケールは小数部の桁数から指数を引いたもの() {
		let cases: [(text: String, unscaled: BigInt, scale: Int)] = [
			("1.50", 150, 2),
			("1E+3", 1, -3),
			("1.23E3", 123, -1),
			("1.23e-3", 123, 5),
			("007.50", 750, 2),
			("+1", 1, 0),
			("-0.00", 0, 2),
			(".5", 5, 1),
			("5.", 5, 0),
			("-.5E-2", -5, 3),
			("0E+10", 0, -10),
		]

		for item in cases {
			let value: BigDecimal? = BigDecimal(item.text)

			#expect(value?.unscaledValue == item.unscaled, "\(item.text)")
			#expect(value?.scale == item.scale, "\(item.text)")
		}
	}

	@Test func 不正な文字列はnil() {
		let invalids: [String] = [
			"",
			"+",
			"-",
			".",
			"-.",
			"e5",
			"1e",
			"1e+",
			"1e+-1",
			"1.2.3",
			" 1",
			"1 ",
			"1_000",
			"0x10",
			"NaN",
			"Infinity",
			"1,000",
			"１",
		]

		for text in invalids {
			#expect(BigDecimal(text) == nil, "\(text)")
		}
	}

	@Test func スケールがIntに収まらない文字列はnil() {
		#expect(BigDecimal("1E+99999999999999999999") == nil)
		#expect(BigDecimal("1E-9223372036854775807") != nil)
		#expect(BigDecimal("0.1E-9223372036854775807") == nil)
	}

	@Test func Substringから作れる() {
		let text: String = "[12.50]"

		#expect(BigDecimal(text.dropFirst().dropLast())?.description == "12.50")
	}

	// MARK: 浮動小数点数

	@Test func 浮動小数点数の値をそのまま展開する() {
		#expect(BigDecimal(exactly: 0.1)?.description == "0.1000000000000000055511151231257827021181583404541015625")
		#expect(BigDecimal(exactly: 0.5)?.description == "0.5")
		#expect(BigDecimal(exactly: -2.0)?.description == "-2")
		#expect(BigDecimal(exactly: 1e16)?.description == "10000000000000000")
		#expect(BigDecimal(exactly: 0.0)?.description == "0")
		#expect(BigDecimal(exactly: -0.0)?.description == "0")
		#expect(BigDecimal(exactly: Float(0.1))?.description == "0.100000001490116119384765625")
	}

	@Test func 非正規化数をそのまま展開する() {
		let value: BigDecimal? = BigDecimal(exactly: Double.leastNonzeroMagnitude)

		#expect(value?.scale == 1074)
		#expect(value?.description.hasPrefix("4.940656458412465441765687928682213723650598026143247644255856825006755072702087518652998363616359923797965646954457177309266567103559397963987747960107818781263007131903114045278458171678489821036887186360569987307230500063874091535649843873124733972731696151400317153853980741262385655911710266585566867681870395603106249319452715914924553293054565444011274801297099995419319894090804165633245247571478690147267801593552386115501348035264934720193790268107107491703332226844753335720832431936092382893458368060106011506169809753078342277318329247904982524730776375927247874656084778203734469699533647017972677717585125660551199131504891101451037862738167250955837389733598993664809941164205702637090279242767544565229087538682506419718265533447265625E-324") == true)
	}

	@Test func 浮動小数点数の最短表現から作る() {
		#expect(BigDecimal(roundTripping: 0.1)?.description == "0.1")
		#expect(BigDecimal(roundTripping: 12345.0)?.description == "12345.0")
		#expect(BigDecimal(roundTripping: 1e16)?.description == "1E+16")
		#expect(BigDecimal(roundTripping: 1e-5)?.description == "0.00001")
		#expect(BigDecimal(roundTripping: -0.0)?.description == "0.0")
		#expect(BigDecimal(roundTripping: Float(0.1))?.description == "0.1")
	}

	@Test func NaNと無限大からは作れない() {
		#expect(BigDecimal(exactly: Double.nan) == nil)
		#expect(BigDecimal(exactly: Double.infinity) == nil)
		#expect(BigDecimal(roundTripping: Double.nan) == nil)
		#expect(BigDecimal(roundTripping: -Double.infinity) == nil)
	}

}
