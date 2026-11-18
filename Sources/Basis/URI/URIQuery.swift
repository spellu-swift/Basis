

public struct URIQuery : Sendable {
	
	public init(
		_ string: String,
	) {
		self.elements = parseQuery(string)
	}
	
	public init(
		_ elements: [(String, String)] = [],
	) {
		self.elements = elements
	}
	
	public internal(set) var elements: [(String, String)]
	
	public subscript (
		_ name: String,
	) -> String? {
		get {
			for element in elements {
				if element.0 == name {
					return element.1
				}
			}
			
			return nil
		}
	}
	
}


extension URIQuery {

	@inlinable
	public var asString: String {
		elements.map {
			"\(encodeQueryComponent($0))=\(encodeQueryComponent($1))"
		}.joined(separator: "&")
	}
	
	@inlinable
	public var asDictionary: OrderedDictionary<String, String> {
		var result: OrderedDictionary<String, String> = [:]

		for (name, value) in elements where result[name] == nil {
			result[name] = value
		}

		return result
	}

}


extension URIQuery : Hashable {
	
	public static func == (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		lhs.asString == rhs.asString
	}
	
	public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(asString)
	}
	
}


private func parseQuery(
	_ string: String?,
) -> [(String, String)] {
	guard let query = string
	else { return [] }
	
	return query.split(separator: "&").map { component in
		let parts = component.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
		let name = String(parts[0])
		let value = parts.count > 1 ? String(parts[1]) : ""

		return (
			URI.percentDecode(name) ?? name,
			URI.percentDecode(value) ?? value,
		)
	}
}


@usableFromInline
func encodeQueryComponent(
	_ string: String,
) -> String {
	let hex = Array("0123456789ABCDEF".utf8)

	var result: [UInt8] = []

	for byte in string.utf8 {
		switch byte {
			case 65...90, 97...122, 48...57, 45, 46, 95, 126:
				result.append(byte)
			default:
				result.append(contentsOf: [37, hex[Int(byte >> 4)], hex[Int(byte & 15)]])
		}
	}

	return result.asString
}
