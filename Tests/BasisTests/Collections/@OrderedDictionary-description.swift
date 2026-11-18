@testable import Basis


@Test
func dictionary_description_nested_indentation() {
	let dictionary: OrderedDictionary<String, OrderedDictionary<String, Int>> = ["outer": ["inner": 1]]

	#expect(dictionary.description == "#D [\n  \"outer\": #D [\n    \"inner\": 1\n  ]\n]")
	#expect(OrderedDictionary<String, Int>().description == "#D [:]")
}


@Test
func dictionary_descriptions_do_not_share_state() async {
	let dictionary: OrderedDictionary<String, Int> = ["a": 1]
	let expected = "#D [\n  \"a\": 1\n]"

	await withTaskGroup(of: String.self) { group in
		for _ in 0..<1000 {
			group.addTask { dictionary.description }
		}
		for await description in group {
			#expect(description == expected)
		}
	}
}
