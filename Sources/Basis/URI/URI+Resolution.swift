

extension URI {

	/// RFC 3986 Section 5.2の厳密な解決。基底URIにスキームがなければnil。
	public func resolved(
		against base: URI,
	) -> URI? {
		guard
			base.isAbsolute
		else { return nil }

		if scheme != nil {
			return removingDotSegments()
		}

		var result: URI = self
		result.scheme = base.scheme

		if authority != nil {
			return result.removingDotSegments()
		}

		result.authority = base.authority

		if path.isEmpty {
			result.path = base.path
			result.query = query ?? base.query
		}
		else {
			if !path.hasPrefix("/") {
				if base.authority != nil && base.path.isEmpty {
					result.path = "/" + path
				} else if let slash = base.path.lastIndex(of: "/") {
					result.path = String(base.path[...slash]) + path
				}
			}
			result.path = Self.removeDotSegments(result.path)
		}
		result.protectPathSyntax()
		return result
	}

	/// エンコードされたドットやスラッシュは区切りとして扱わない。
	public func removingDotSegments() -> URI {
		var result: URI = self
		result.path = Self.removeDotSegments(path)
		result.protectPathSyntax()
		return result
	}

	internal static func removeDotSegments(
		_ path: String,
	) -> String {
		var input: Substring = path[...]
		var output: String = ""
		while !input.isEmpty {
			if input.hasPrefix("../") {
				input = input.dropFirst(3)
			} else if input.hasPrefix("./") {
				input = input.dropFirst(2)
			} else if input.hasPrefix("/./") || input == "/." {
				input = input.dropFirst(2)
				if input.isEmpty { input = "/" }
			} else if input.hasPrefix("/../") || input == "/.." {
				input = input.dropFirst(3)
				if input.isEmpty { input = "/" }
				if let slash = output.lastIndex(of: "/") {
					output.removeSubrange(slash...)
				} else {
					output = ""
				}
			} else if input == "." || input == ".." {
				input = ""
			} else {
				let start = input.first == "/" ? input.index(after: input.startIndex) : input.startIndex
				let end = input[start...].firstIndex(of: "/") ?? input.endIndex
				output += input[..<end]
				input = input[end...]
			}
		}
		return output
	}

}
