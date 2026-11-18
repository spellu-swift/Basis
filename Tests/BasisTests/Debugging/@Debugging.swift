import Basis


@Test func printMacro() {
	let value_1: String? = nil
	let value_2: String? = "foo"

	#print(30, "abc", value_1, value_2)
	#print(30, "abc", value_1, value_2, nilString: "<>")
}


@Test func printMacro_withTerminator() {
	let value_1: String? = nil
	let value_2: String? = "foo"
	
	#print(30, "abc", value_1, value_2, terminator: "")
	#print(30, "abc", value_1, value_2)
}


