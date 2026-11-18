import Basis


private extension PolymorphyValues {
	@PolymorphyEntry var number: Int = 123
}


@Test func polymorphyValues_number() {
	
	#expect(PolymorphyValues().number == 123)
	
}
