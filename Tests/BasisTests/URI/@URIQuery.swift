@testable import Basis


@Test
func query_flags_empty_values_and_repeated_names() {
	let query = URIQuery("flag&empty=&a=1&a=2&=value")

	#expect(query["flag"] == "")
	#expect(query["empty"] == "")
	#expect(query[""] == "value")
	#expect(query["a"] == "1")
	#expect(query.asDictionary["a"] == "1")
	#expect(query.elements.count == 5)
	#expect(URIQuery("").elements.isEmpty)
}


@Test(arguments: ["", "a b", "a&b=c", "日本語🙂", "+%?#/", "-._~"])
func query_components_roundtrip(value: String) {
	let query = URIQuery([(value, value)])

	#expect(URIQuery(query.asString) == query)
	#expect(URIQuery(query.asString)[value] == value)
}


@Test
func query_decodes_names_and_preserves_literal_plus() {
	let query = URIQuery("a%20b=%E6%97%A5%E6%9C%AC%E8%AA%9E&plus=+&bad=%ZZ")

	#expect(query["a b"] == "日本語")
	#expect(query["plus"] == "+")
	#expect(query["bad"] == "%ZZ")
	#expect(URIQuery([("a", "b&c=d")]).asString == "a=b%26c%3Dd")
}
