@testable import Basis


@Test
func ordered_dictionary_updates_preserve_order_and_uniqueness() {
	var dictionary = OrderedDictionary<String, Int>([("a", 1), ("b", 2)])
	dictionary["a"] = 3
	dictionary.merge([("b", 4), ("c", 5)]) { $0 + $1 }

	#expect(dictionary.keys == ["a", "b", "c"])
	#expect(dictionary.values == [3, 6, 5])
	#expect(dictionary.asDictionary == ["a": 3, "b": 6, "c": 5])

	dictionary["a"] = nil

	#expect(dictionary.keys == ["b", "c"])
	#expect(dictionary["a"] == nil)
}


@Test
func ordered_dictionary_omitted_values_do_not_create_keys() {
	let dictionary = OrderedDictionary<String, Int>(
		[("a", nil), ("a", Optional(2))],
	)

	#expect(dictionary.asDictionary == ["a": 2])
}
