@testable import Basis


@Suite struct URI意味論テスト {

	// RFC 3986 Section 5.4の正常例・異常例。
	@Test(arguments: [
		("g:h", "g:h"), ("g", "http://a/b/c/g"), ("./g", "http://a/b/c/g"),
		("g/", "http://a/b/c/g/"), ("/g", "http://a/g"), ("//g", "http://g"),
		("?y", "http://a/b/c/d;p?y"), ("g?y", "http://a/b/c/g?y"),
		("#s", "http://a/b/c/d;p?q#s"), ("g#s", "http://a/b/c/g#s"),
		("g?y#s", "http://a/b/c/g?y#s"), (";x", "http://a/b/c/;x"),
		("g;x", "http://a/b/c/g;x"), ("g;x?y#s", "http://a/b/c/g;x?y#s"),
		("", "http://a/b/c/d;p?q"), (".", "http://a/b/c/"), ("./", "http://a/b/c/"),
		("..", "http://a/b/"), ("../", "http://a/b/"), ("../g", "http://a/b/g"),
		("../..", "http://a/"), ("../../", "http://a/"), ("../../g", "http://a/g"),
		("../../../g", "http://a/g"), ("../../../../g", "http://a/g"),
		("/./g", "http://a/g"), ("/../g", "http://a/g"),
		("g.", "http://a/b/c/g."), (".g", "http://a/b/c/.g"),
		("g..", "http://a/b/c/g.."), ("..g", "http://a/b/c/..g"),
		("./../g", "http://a/b/g"), ("./g/.", "http://a/b/c/g/"),
		("g/./h", "http://a/b/c/g/h"), ("g/../h", "http://a/b/c/h"),
		("g;x=1/./y", "http://a/b/c/g;x=1/y"), ("g;x=1/../y", "http://a/b/c/y"),
		("g?y/./x", "http://a/b/c/g?y/./x"), ("g?y/../x", "http://a/b/c/g?y/../x"),
		("g#s/./x", "http://a/b/c/g#s/./x"), ("g#s/../x", "http://a/b/c/g#s/../x"),
		("http:g", "http:g"),
	])
	func RFC3986の相対参照解決(_ sample: (String, String)) throws {
		let base = try URI.parse("http://a/b/c/d;p?q")
		let reference = try URI.parse(sample.0)
		#expect(reference.resolved(against: base)?.asString == sample.1)
	}

	@Test
	func 解決時の空要素と基底の条件() throws {
		let base = try URI.parse("https://host/a?x#old")
		#expect(try URI.parse("?").resolved(against: base)?.asString == "https://host/a?")
		#expect(try URI.parse("#").resolved(against: base)?.asString == "https://host/a?x#")
		#expect(try URI.parse("//").resolved(against: base)?.asString == "https://")
		#expect(try URI.parse("a").resolved(against: URI.parse("https://host"))?.asString == "https://host/a")
		#expect(try URI.parse("b").resolved(against: URI.parse("s:a"))?.asString == "s:b")
		#expect(try URI.parse("b").resolved(against: URI.parse("s:"))?.asString == "s:b")
		#expect(try URI.parse("x").resolved(against: URI.parse("a/b")) == nil)
		#expect(try URI.parse("https://host/").resolved(against: URI.parse("")) == nil)
		#expect(try URI.parse("%2e%2e/x").resolved(against: base)?.path == "/%2e%2e/x")
	}

	@Test(arguments: [
		("/a/b/c/./../../g", "/a/g"), ("mid/content=5/../6", "mid/6"),
		("../a", "a"), ("./a", "a"), (".", ""), ("..", ""), ("", ""),
		("/..", "/"), ("/a/.", "/a/"), ("/a/..", "/"),
		("a/../b", "/b"), ("/a//b/./c/", "/a//b/c/"),
		("/%2E/%2e%2e/a%2Fb", "/%2E/%2e%2e/a%2Fb"),
	])
	func ドット除去はパスの区切りだけを解釈する(_ sample: (String, String)) {
		let uri = URI(path: sample.0, query: "/../", fragment: "/./")
		let result = uri.removingDotSegments()
		#expect(result.path == sample.1)
		#expect(result.query == uri.query)
		#expect(result.fragment == uri.fragment)
	}

	@Test
	func Path操作後もauthorityとschemeを誤認させない() throws {
		let uri = try URI.parse("s:/a/..//b")
		for result in [uri.removingDotSegments(), uri.normalized(), try #require(uri.resolved(against: URI.parse("s:/")))] {
			#expect(result.asString == "s:/.//b")
			#expect(result.authority == nil)
			#expect(URI(result.asString) == result)
			#expect(result.normalized() == result)
		}
		let relative = try URI.parse("./a:b").removingDotSegments()
		#expect(relative.scheme == nil)
		#expect(URI(relative.asString) == relative)
	}

	@Test
	func 正規化は構文上の同値を揃える() throws {
		let uri = try URI.parse("HTTP://Us%65r@%45xample.COM:80/a/../b/%7Euser/%2f?q=%41%26#%7a")
		let result = uri.normalized()
		#expect(result.asString == "http://User@example.com:80/b/~user/%2F?q=A%26#z")
		#expect(result.normalized() == result)
		#expect(uri.scheme == "HTTP")
		var mutable = uri
		mutable.normalize()
		#expect(mutable == result)
		#expect(try URI.parse("https://EXAMPLE.com").normalized().asString == "https://example.com")
		#expect(try URI.parse("s://[2001:DB8::A]/%2e%2e/b").normalized().asString == "s://[2001:db8::a]/b")
		#expect(try URI.parse("s://%c3%a9.EXAMPLE").normalized().host == "%C3%A9.example")
		#expect(try URI.parse("//?#").normalized().asString == "//?#")
	}

	@Test
	func 相対参照の正規化は基底との位置関係を保持する() throws {
		let uri = try URI.parse("../a/./%7e")
		#expect(uri.normalized().asString == "../a/./~")
		let base = try URI.parse("https://example.com/b/c")
		#expect(uri.normalized().resolved(against: base) == uri.resolved(against: base)?.normalized())
	}

	@Test
	func エンコードされたファイル名へ保存できる() throws {
		try Directory.withTemporary { directory in
			let file = directory[file: "猫 %?#.txt"]
			let data = Binary("URIの保存テスト")
			try data.save(to: file.uri, atomic: true)
			#expect(try file.load() == data)
			#expect(try file.uri.load() == data)
			#expect(throws: GeneralError.self) {
				try data.save(to: URI.parse("https://example.com/a"))
			}
		}
	}

	@Test
	func 生成した参照を再解決すると対象URIに戻る() throws {
		let bases: [URI]
		= try [
			"s:", "s:a", "s:a/b", "s:a/b/", "s:/a", "s:/a/b",
			"s://", "s:///a", "s://h", "s://h?x", "s://h/a/b",
			"s://h/a//b/", "s://h/a/../b/c", "s://h/.//b", "S://h/a",
			"s://other/a", "s://u@h:80/a", "s://h/a?", "s://[::1]/a", "s://h/a#f",
		].map { try URI.parse($0) }

		let targets: [URI]
		= try [
			"s:", "s:?", "s:?x", "s:#", "s:a", "s:a/", "s:a/b", "s:a:b",
			"s:/", "s:/a", "s:/a/", "s:/a/b", "s:/a/..", "s:/a/./b", "s:a/../b",
			"s:/.//b", "s://", "s://?", "s:///a", "s://h", "s://h?", "s://h?x",
			"s://h#", "s://h#f", "s://h/", "s://h/a", "s://h/a/", "s://h/a/b",
			"s://h/a//b", "s://h/a///b/", "s://h/a/b:c", "s://h/a/..", "s://h/a/./b",
			"s://h/a?", "s://h/a?x", "s://h/a#", "s://h/a#f", "s://h/%2e/%2F/%7e",
			"s://h/a/../../c", "S://h/a", "t://h/a", "s://other/a", "s://u@h:80/a",
			"s://h:/a", "s://[::1]/a", "s://[v1.a:b]/a",
		].map { try URI.parse($0) }

		for base in bases {
			for target in targets {
				let reference = try #require(target.relative(to: base))
				let reparsed = try URI.parse(reference.asString)
				#expect(reparsed == reference)
				#expect(reparsed.resolved(against: base) == target.removingDotSegments())
			}
		}
	}

	@Test
	func 同値性判定を追加しても構造的な等値性は変わらない() throws {
		let original = try URI.parse("HTTP://Example.COM/a/../%7e")
		let normalized = try URI.parse("http://example.com/~")
		#expect(original.isEquivalent(to: normalized))
		#expect(original != normalized)
		#expect(Set([original, normalized]).count == 2)
	}

	@Test
	func Query項目を削除しても残りの表記と意味は変わらない() throws {
		let original = try URI.parse("https://h/a?drop=1&flag&keep=%2f&drop=2&keep=+&empty=#f")
		let result = original.removingQueryItems(named: "drop")
		#expect(result.queryItems == [
			.init(name: "flag"), .init(name: "keep", value: "/"),
			.init(name: "keep", value: "+"), .init(name: "empty", value: ""),
		])
		#expect(result.asString == "https://h/a?flag&keep=%2f&keep=+&empty=#f")
		#expect(URI(result.asString) == result)
		#expect(result.removingQueryItems(named: "drop") == result)
	}

}
