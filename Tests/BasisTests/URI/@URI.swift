@testable import Basis


@Suite struct URI単体テスト {

	@Test
	func 構成要素の生成と変更() throws {
		var uri = URI(path: "")
		#expect(uri.asString == "")
		#expect(uri.isRelative)
		#expect(!uri.isAbsolute)
		#expect(uri.host == nil)
		uri.scheme = "https"
		uri.authority = .init(userInfo: "user:pass", host: "example.com", port: "080")
		uri.path = "/a%2Fb"
		uri.query = "x=%26"
		uri.fragment = ""
		#expect(uri.asString == "https://user:pass@example.com:080/a%2Fb?x=%26#")
		#expect(uri.description == uri.asString)
		#expect(uri.isAbsolute)
		#expect(!uri.isRelative)
		#expect(uri.host == "example.com")
		#expect(try URI.parse(uri.asString) == uri)
	}

	@Test(arguments: [
		"", "?", "#", "?#", "//", "///", "/", "../cat", "./a:b", "/a:b", "a/b:c",
		"https://example.com", "app:///", "icloud:///Documents", "file:/tmp/a",
		"mailto:John.Doe@example.com", "urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
		"a+1-2.3:", "//user:password@host:001/a?b/c?d#e/f?g",
		"https://192.0.2.1/", "https://999.999.999.999/", "https://[2001:db8::1]:80/",
		"https://[vF.a:b]/", "https://%E6%97%A5.example/%FF?x=%00#%7e",
		"/a!$&'()*+,;=:@/b?c!$&'()*+,;=:@/?#d!$&'()*+,;=:@/?",
	])
	func 解析と文字列化の往復(_ string: String) throws {
		let uri = try URI.parse(string)
		#expect(uri.asString == string)
		#expect(URI(uri.asString) == uri)
	}

	@Test(arguments: [
		"1abc:foo", ":foo", "a b", "https://日本語/", "/日本語", "a\\b", "a\nb", "a\r", "a\t", "a\u{0}",
		"/%", "/%0", "/%GG", "/[a]", "?a=[b]", "#a#b", "//user@@host/", "//host:abc/",
		"//host:-1/", "//host:1:2/", "//[invalid]/", "//[::1]extra/", "//[::1/", "//host]/",
	])
	func 不正な参照を拒否する(_ string: String) {
		#expect(URI(string) == nil)
		#expect(throws: GeneralError.self) { try URI.parse(string) }
	}

	@Test
	func 空と未指定を区別する() throws {
		let absent = try URI.parse("")
		let empty = try URI.parse("//?#")
		#expect(absent.authority == nil)
		#expect(absent.query == nil)
		#expect(absent.fragment == nil)
		#expect(empty.authority == .init(host: ""))
		#expect(empty.query == "")
		#expect(empty.fragment == "")
		#expect(Set([absent, empty, try URI.parse("?"), try URI.parse("#")]).count == 4)
	}

	@Test
	func Hashableは正規化前の構造で比較する() throws {
		let original = try URI.parse("HTTP://Example.COM/%7e")
		let normalized = original.normalized()
		#expect(original != normalized)
		#expect(Set([original, try URI.parse(original.asString), normalized]).count == 2)
	}

}


@Suite struct URIAuthority単体テスト {

	@Test(arguments: [
		"", "example.com", "user:password@example.com:80", "@:", "host:", "host:00080",
		"host:99999999999999999999999999999", "192.0.2.1", "%E6%97%A5.example",
		"[::]", "[::1]", "[2001:db8::1]:443", "[1:2:3:4:5:6:7:8]",
		"[1:2:3:4:5:6:7::]", "[::1:2:3:4:5:6:7]", "[::ffff:192.0.2.128]",
		"[1:2:3:4:5:6:192.0.2.1]", "[::192.0.2.1]", "[v1.a:b]", "[VF.!$&'()*+,;=:_~-]",
	])
	func 正常なAuthorityの往復(_ string: String) throws {
		let authority = try #require(URI.Authority(string))
		#expect(authority.asString == string)
		#expect(URI.Authority(authority.asString) == authority)
	}

	@Test(arguments: [
		"user@@host", "host:abc", "host:-1", "host:+80", "host:８０", "host:80:90",
		"host/path", "host?query", "host#fragment", "a b", "%GG", "user%0@host",
		"[]", "[1]", "[:::]", "[:1]", "[1:]", "[1::2::3]", "[1:2:3:4:5:6:7]",
		"[1:2:3:4:5:6:7:8:9]", "[1:2:3:4:5:6:7:8::]", "[12345::]", "[gggg::]",
		"[::ffff:192.0.2.256]", "[::ffff:192.0.2]", "[::ffff:192.0.2.01]",
		"[192.0.2.1]", "[1:2:3:4:5:192.0.2.1]", "[192.0.2.1::]",
		"[::1%25en0]", "[v.a]", "[v1.]", "[vG.a]", "[v1.a%20]", "[v1.a@b]", "[::1]x",
	])
	func 不正なAuthorityを拒否する(_ string: String) {
		#expect(URI.Authority(string) == nil)
	}

	@Test
	func 構成要素の変更と数値ポート() {
		var authority = URI.Authority(host: "")
		#expect(authority.portNumber == nil)
		authority.userInfo = "name"
		authority.host = "[::1]"
		authority.port = "00080"
		#expect(authority.asString == "name@[::1]:00080")
		#expect(authority.portNumber == 80)
		for port in ["", "-1", "+80", "a", "99999999999999999999999999999"] {
			authority.port = port
			#expect(authority.portNumber == nil)
		}
		authority.port = "0"
		#expect(authority.portNumber == 0)
	}

}


@Suite struct URIPercentEncoding単体テスト {

	@Test
	func コンポーネント別の許可文字() {
		let source = "AZaz09-._~!$&'()*+,;=:@/?#[]% "
		let common = "AZaz09-._~!$&'()*+,;="
		#expect(URI.percentEncode(source, component: .userInfo) == common + ":%40%2F%3F%23%5B%5D%25%20")
		#expect(URI.percentEncode(source, component: .host) == common + "%3A%40%2F%3F%23%5B%5D%25%20")
		#expect(URI.percentEncode(source, component: .path) == common + ":@/%3F%23%5B%5D%25%20")
		#expect(URI.percentEncode(source, component: .pathSegment) == common + ":@%2F%3F%23%5B%5D%25%20")
		#expect(URI.percentEncode(source, component: .query) == common + ":@/?%23%5B%5D%25%20")
		#expect(URI.percentEncode(source, component: .fragment) == common + ":@/?%23%5B%5D%25%20")
	}

	@Test(arguments: ["", "日本語🙂", "a b", "+%?#/", "\u{0}\r\n", "%2F", "e\u{301}"])
	func UTF8の往復(_ string: String) {
		for component: URI.Component in [.userInfo, .host, .path, .pathSegment, .query, .fragment] {
			#expect(URI.percentDecode(URI.percentEncode(string, component: component)) == string)
		}
		#expect(URI.percentEncode("猫", component: .path) == "%E7%8C%AB")
		#expect(URI.percentDecode("%2f+") == "/+")
	}

	@Test(arguments: ["%", "%0", "%GG", "%1g", "%FF", "%80", "%C0%AF", "%E2%82", "%ED%A0%80", "%F4%90%80%80"])
	func 不正なエスケープとUTF8を拒否する(_ string: String) {
		#expect(URI.percentDecode(string) == nil)
	}

}


@Suite struct URI便利操作単体テスト {

	@Test
	func Queryの順序と値の有無を保持する() throws {
		let uri = try URI.parse("?flag&empty=&a=1&a=2&=value&plus=+&a%20b=%E7%8C%AB&bad=%FF&&")
		#expect(uri.queryItems == [
			.init(name: "flag"), .init(name: "empty", value: ""),
			.init(name: "a", value: "1"), .init(name: "a", value: "2"),
			.init(name: "", value: "value"), .init(name: "plus", value: "+"),
			.init(name: "a b", value: "猫"), .init(name: "bad", value: "%FF"),
			.init(name: ""), .init(name: ""),
		])
		#expect(URI(path: "").queryItems.isEmpty)
		#expect(URI(path: "", query: "").queryItems.isEmpty)
		var item = URI.QueryItem(name: "a")
		item.name = "b"
		item.value = ""
		#expect(Set([item, .init(name: "b", value: ""), .init(name: "b")]).count == 2)
	}

	@Test
	func Query項目を追加する() throws {
		let uri = try URI.parse("https://example.com/p?x=%2f#f")
		let appended = uri.appendingQueryItem(name: "a&=+", value: "猫 +%")
		#expect(appended.asString == "https://example.com/p?x=%2f&a%26%3D%2B=%E7%8C%AB%20%2B%25#f")
		#expect(appended.queryItems.last == .init(name: "a&=+", value: "猫 +%"))
		#expect(uri.query == "x=%2f")
		#expect(URI(path: "").appendingQueryItem(name: "flag").asString == "?flag")
		#expect(URI(path: "", query: "").appendingQueryItem(name: "a", value: "").asString == "?a=")
		#expect(URI(path: "").appendingQueryItem(name: "").query == "")
	}

	@Test
	func Pathのセグメントと末尾要素() {
		#expect(URI(path: "").pathSegments == [])
		#expect(URI(path: "/").pathSegments == [""])
		#expect(URI(path: "/a//b%2Fc/").pathSegments == ["a", "", "b%2Fc", ""])
		#expect(URI(path: "a/b").pathSegments == ["a", "b"])
		#expect(URI(path: "/a/b%2Fc//").lastPathComponent == "b%2Fc")
		#expect(URI(path: "").lastPathComponent == "")
		#expect(URI(path: "/").lastPathComponent == "")
	}

	@Test
	func Path要素の追加() throws {
		let uri = try URI.parse("https://example.com/docs?x#f")
		#expect(uri.appendingPathComponent("cat.png").asString == "https://example.com/docs/cat.png?x#f")
		#expect(uri.appendingPathComponent("猫/a%2F").path == "/docs/%E7%8C%AB%2Fa%252F")
		#expect(URI(path: "a/").appendingPathComponent("b").path == "a/b")
		#expect(URI(path: "").appendingPathComponent("b").path == "b")
		#expect(URI(path: "").appendingPathComponent("a:b").asString == "./a:b")
		#expect(try URI.parse("//host").appendingPathComponent("b").asString == "//host/b")
		#expect(uri.appendingPathComponent("").path == "/docs/")
		#expect(uri.path == "/docs")
	}

	@Test(arguments: [("/a/b/", "/a/"), ("a/b", "a/"), ("/a", "/"), ("a", ""), ("/", "/"), ("", ""), ("/a//b", "/a//")])
	func Pathの末尾要素を削除する(_ sample: (String, String)) {
		let uri = URI(path: sample.0, query: "", fragment: "f")
		let result = uri.deletingLastPathComponent()
		#expect(result.path == sample.1)
		#expect(result.query == "")
		#expect(result.fragment == "f")
		#expect(uri.path == sample.0)
	}

	@Test
	func Fileの生成とパス取得() throws {
		let path = "/tmp/猫 a%?#.txt"
		let uri = URI.file(path)
		#expect(uri.authority == .init(host: ""))
		#expect(uri.asString == "file:///tmp/%E7%8C%AB%20a%25%3F%23.txt")
		#expect(uri.filePath?.asString == path)
		#expect(uri.isFileURI)
		#expect(URI.file(FilePath(noCheck: path)) == uri)
		#expect(FilePath(noCheck: path).uri == uri)
		#expect(File(at: path).uri == uri)
		#expect(Directory(at: path).uri.isFileURI)
		#expect(URI.file("relative").filePath == FilePath("relative").absoluted)
		#expect(URI.file("").filePath?.isAbsolute == true)
		#expect(try URI.parse("FILE://LOCALHOST/tmp/a").filePath?.asString == "/tmp/a")
		#expect(try URI.parse("file:/tmp/a").filePath?.asString == "/tmp/a")
	}

	@Test(arguments: ["https://localhost/a", "file://remote/a", "file://u@localhost/a", "file://localhost:80/a", "file:relative", "file:", "file:///a%00b", "file:///a%2fb", "file:///%FF"])
	func ローカルパスへ変換できない参照(_ string: String) throws {
		#expect(try URI.parse(string).filePath == nil)
	}

}


@Suite struct URIRelative単体テスト {

	@Test(arguments: [
		("https://h/a/b", "https://h/a/c", "c"),
		("https://h/a/b/c", "https://h/d/e", "../../d/e"),
		("https://h/a/b", "https://h/a/", "./"),
		("https://h/a/b/", "https://h/a/b", "../b"),
		("https://h/a/b", "https://h/", "../"),
		("https://h/a/b", "https://h/a/b", ""),
		("https://h/a/b?x#old", "https://h/a/b?x#new", "#new"),
		("https://h/a/b?x", "https://h/a/b?y", "?y"),
		("https://h/a/b?x", "https://h/a/b?", "?"),
		("https://h/a/b?x", "https://h/a/b", "b"),
		("https://h/a/?x", "https://h/a/", "./"),
		("https://h/a/b?x", "https://h/a/c?x", "c?x"),
		("https://h/a/b?x#old", "https://h/a/b?x", ""),
		("https://h/a/b", "https://h/a/b#", "#"),
		("https://h", "https://h/", "./"),
		("https://h", "https://h/a", "a"),
		("https://h?x", "https://h", "//h"),
		("https://h/", "https://h", "//h"),
		("https://h/a/b", "https://other/c", "//other/c"),
		("https://h/a/b", "https:///c", "///c"),
		("https://h/a/b", "https:/c", "https:/c"),
		("https://h/a/b", "http://h/a/c", "http://h/a/c"),
		("https://h/a/b", "HTTPS://h/a/c", "HTTPS://h/a/c"),
		("https://h/a/b", "https://H/a/c", "//H/a/c"),
		("https://h/a/b", "https://u@h:080/c", "//u@h:080/c"),
		("https://h/a/b", "https://h/a/a:b", "./a:b"),
		("https://h/a/b", "https://h/a//c", ".//c"),
		("https://h/a//b", "https://h/a/c", "../c"),
		("https://h/a/../b/c", "https://h/b/d", "d"),
		("https://h/a/b", "https://h/a/./c/../d", "d"),
		("https://h/a/b", "https://h/a/%2e%2e/%2Fc", "%2e%2e/%2Fc"),
		("s:a", "s:b", "b"),
		("s:a/b", "s:a/c", "c"),
		("s:a/b", "s:c", "s:c"),
		("s:a/b", "s:/c", "/c"),
		("s:", "s:a", "a"),
		("s:a", "s:", "./"),
		("s:", "s:", ""),
	])
	func 基底と対象から参照を生成する(_ sample: (String, String, String)) throws {
		let base = try URI.parse(sample.0)
		let target = try URI.parse(sample.1)
		let reference = try #require(target.relative(to: base))

		#expect(reference.asString == sample.2)
		#expect(reference.resolved(against: base) == target.removingDotSegments())
		#expect(base.asString == sample.0)
		#expect(target.asString == sample.1)
	}

	@Test(arguments: [
		("", "https://h/"), ("a/b", "https://h/"),
		("https://h/", ""), ("https://h/", "../a"), ("a", "b"),
	])
	func スキームを持たない基底や対象は拒否する(_ sample: (String, String)) throws {
		let base = try URI.parse(sample.0)
		let target = try URI.parse(sample.1)
		#expect(target.relative(to: base) == nil)
	}

}


@Suite struct URIEquivalent単体テスト {

	@Test(arguments: [
		("HTTP://Example.COM/a/../b/%7Euser", "http://example.com/b/~user"),
		("s://Us%65r@%45XAMPLE.com/a", "s://User@example.com/a"),
		("s:/%41%2f?q=%7e%26#%7a", "s:/A%2F?q=~%26#z"),
		("s://[2001:DB8::A]/", "s://[2001:db8::a]/"),
		("s://%c3%a9.EXAMPLE/%ff", "s://%C3%A9.example/%FF"),
		("s:/a/%2e%2e/b", "s:/b"),
		("../%7e", "../~"), ("//EXAMPLE.com/%7e", "//example.com/~"),
		("", ""), ("//?#", "//?#"),
	])
	func 正規化で同値になる(_ sample: (String, String)) throws {
		let left = try URI.parse(sample.0)
		let right = try URI.parse(sample.1)
		#expect(left.isEquivalent(to: right))
		#expect(right.isEquivalent(to: left))
		#expect(left.isEquivalent(to: left))
		#expect(left.asString == sample.0)
		#expect(right.asString == sample.1)
	}

	@Test(arguments: [
		("http://h/", "https://h/"), ("http://h/", "http://h:80/"),
		("http://h", "http://h/"), ("s://h:080/", "s://h:80/"),
		("s://User@h/", "s://user@h/"), ("s:/A", "s:/a"),
		("s:/a%2Fb", "s:/a/b"), ("s:/a%3Fb", "s:/a?b"),
		("s:/?a=1&b=2", "s:/?b=2&a=1"), ("s:/?a=1&a=2", "s:/?a=2&a=1"),
		("s:/?flag", "s:/?flag="), ("s:/?x=+", "s:/?x=%20"),
		("s:/#a", "s:/#b"), ("s:/", "s:/#"), ("s:/", "s:/?"),
		("s:/", "s:///"), ("a", "./a"), ("../a", "a"),
		("s://[::1]/", "s://[0:0:0:0:0:0:0:1]/"),
	])
	func 正規化の範囲外の違いは同値にしない(_ sample: (String, String)) throws {
		let left = try URI.parse(sample.0)
		let right = try URI.parse(sample.1)
		#expect(!left.isEquivalent(to: right))
		#expect(!right.isEquivalent(to: left))
	}

}


@Suite struct URIQuery削除単体テスト {

	@Test(arguments: [
		("", "a", ""), ("?", "a", "?"), ("?", "", "?"),
		("?a=1", "missing", "?a=1"), ("?a=1", "a", ""),
		("?a=1&b=2&a=3", "a", "?b=2"),
		("?a&b=&a=", "a", "?b="),
		("?a=1&b=2&c=3", "b", "?a=1&c=3"),
		("?a=1&b=2", "b", "?a=1"),
		("?%61=1&a=2&A=3", "a", "?A=3"),
		("?a%20b=1&keep=%2f&a+b=2", "a b", "?keep=%2f&a+b=2"),
		("?a%2Bb=1&a+b=2&keep=+", "a+b", "?keep=+"),
		("?%E7%8C%AB=1&keep=%ff", "猫", "?keep=%ff"),
		("?%26%3D=1&keep=a=b", "&=", "?keep=a=b"),
		("?%FF=1&keep=2", "%FF", "?keep=2"),
		("?=value&&a=1&", "", "?a=1"),
		("?&&", "", ""), ("?a=1&", "a", "?"),
		("?&a=1&", "a", "?&"),
	])
	func 一致する全項目だけを削除する(_ sample: (String, String, String)) throws {
		let original = try URI.parse("https://h/p" + sample.0 + "#f")
		let result = original.removingQueryItems(named: sample.1)
		#expect(result.asString == "https://h/p" + sample.2 + "#f")
		#expect(original.asString == "https://h/p" + sample.0 + "#f")
	}

}
