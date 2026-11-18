

@Default struct AAA : Equatable {
	let n: Int
	var m: Int = 34
}


@Test("@Defaultマクロ")
func defaultMacro_1() async throws {
	#expect(AAA.default.n == 0)
	#expect(AAA.default.m == 34)
}


