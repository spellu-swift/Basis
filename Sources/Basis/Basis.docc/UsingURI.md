# URI の使い方

URIを構成要素に分けて扱い、相対参照の解決やクエリの操作を行う。

## Overview

``URI``は、`https://example.com/docs?lang=ja#intro`のようなURIを、構成要素ごとに保持する値型です。構文と相対参照の解決は[RFC 3986](https://www.rfc-editor.org/rfc/rfc3986)に、ファイルURIは[RFC 8089](https://www.rfc-editor.org/rfc/rfc8089)に従います。

URIは次の構成要素からなります。

```
https://user@example.com:8080/docs/guide.html?lang=ja#intro
└─┬─┘   └────────┬────────┘└───────┬───────┘ └──┬──┘ └─┬─┘
scheme       authority            path         query fragment
```

各構成要素は、パーセントエンコードされた文字列のまま保持します。URIは文字列を解析して保持するだけで、ネットワークには接続しません。

## URI を作る

文字列を解析して作ります。URIとして不正な文字列なら`nil`になります。

```swift
let text: String = "https://user@example.com:8080/docs/guide.html?lang=ja&q=a%20b#intro"

guard let uri = URI(text)
else { return }
```

エラーとして扱いたい場合は``URI/parse(_:)``を使います。不正な文字列なら``GeneralError/invalidFormat(_:)``を投げます。

```swift
let uri: URI = try URI.parse(text)
```

### 文字列リテラルから作る場合の注意

`URI`は文字列リテラルから作れる型です。そのため、リテラルを直接渡すと`nil`にならず、URIとして不正なら実行時エラーで停止します。

```swift
let home: URI = "https://example.com/"        // URI（Optionalではない）
let same: URI = URI("https://example.com/")   // これもリテラルからの変換になる

let text: String = "https://example.com/"
let parsed: URI? = URI(text)                  // 変数から作るとOptional
```

リテラルを使うのは、正しいことがわかっている固定のURIだけにしてください。外部から受け取った文字列は、変数を渡して`nil`を確かめます。

### 構成要素から作る

構成要素を指定して作ることもできます。パスやクエリは、エンコード済みの文字列で渡します。

```swift
let uri: URI = URI(
	scheme: "https",
	authority: .init(host: "example.com"),
	path: "/a%20b",
	query: "x=1",
)
uri.asString   // "https://example.com/a%20b?x=1"
```

## 構成要素を取り出す

```swift
uri.scheme                  // "https"
uri.authority?.userInfo     // "user"
uri.host                    // "example.com"
uri.authority?.port         // "8080"
uri.authority?.portNumber   // 8080
uri.path                    // "/docs/guide.html"
uri.query                   // "lang=ja&q=a%20b"
uri.fragment                // "intro"

uri.pathSegments            // ["docs", "guide.html"]
uri.lastPathComponent       // "guide.html"

uri.isAbsolute              // true（スキームがある）
uri.asString                // 元の文字列
```

構成要素はプロパティとして変更できます。

```swift
var uri: URI = "https://example.com/a"
uri.path = "/b"
uri.fragment = "top"
uri.asString   // "https://example.com/b#top"
```

## パスを操作する

``URI/appendingPathComponent(_:)``は、エンコードしていない1つの要素を追加します。要素の中の`/`や空白はエンコードされます。

```swift
let files: URI = "https://example.com/files/"

files.appendingPathComponent("a/b c.txt").asString
// "https://example.com/files/a%2Fb%20c.txt"

URI("https://example.com/files/a.txt").deletingLastPathComponent().asString
// "https://example.com/files/"
```

## クエリを操作する

``URI/queryItems``で、クエリを名前と値の組として得られます。値はデコードされます。順序と重複はそのまま保持します。

```swift
uri.queryItems.map { "\($0.name)=\($0.value ?? "")" }
// ["lang=ja", "q=a b"]
```

項目の追加と削除では、エンコードしていない文字列を渡します。

```swift
let search: URI = "https://example.com/search"

search
	.appendingQueryItem(name: "q", value: "日本 語")
	.appendingQueryItem(name: "flag")
	.asString
// "https://example.com/search?q=%E6%97%A5%E6%9C%AC%20%E8%AA%9E&flag"

URI("https://example.com/s?a=1&b=2&a=3").removingQueryItems(named: "a").asString
// "https://example.com/s?b=2"
```

すべての項目を削除すると、クエリそのものがなくなります。

### URIQuery

クエリの文字列だけを扱う場合は``URIQuery``を使います。

```swift
let query: URIQuery = URIQuery("a=1&b=x%20y&a=2")

query["a"]        // "1"（最初に現れた値）
query["b"]        // "x y"
query.asString    // "a=1&b=x%20y&a=2"

URIQuery([("name", "山田 太郎"), ("age", "20")]).asString
// "name=%E5%B1%B1%E7%94%B0%20%E5%A4%AA%E9%83%8E&age=20"
```

## 相対参照を解決する

``URI/resolved(against:)``で、相対参照を基底のURIに対して解決します。基底のURIにスキームがなければ`nil`です。

```swift
let base: URI = "https://example.com/docs/guide/index.html"

URI("../api/list.html").resolved(against: base)?.asString
// "https://example.com/docs/api/list.html"

URI("?page=2").resolved(against: base)?.asString
// "https://example.com/docs/guide/index.html?page=2"

URI("//cdn.example.com/a.js").resolved(against: base)?.asString
// "https://cdn.example.com/a.js"
```

逆に、2つのURIから相対参照を作るには``URI/relative(to:)``を使います。

```swift
URI("https://example.com/docs/api/list.html").relative(to: base)?.asString
// "../api/list.html"

URI("https://other.example/x").relative(to: base)?.asString
// "//other.example/x"（ホストが違えばホストから書く）
```

## URI を比べる

`==`は構成要素の表記をそのまま比べます。大文字・小文字やエンコードの違いを無視して比べるには``URI/isEquivalent(to:)``を使います。

```swift
let a: URI = "HTTP://Example.COM/%7e"
let b: URI = "http://example.com/~"

a == b               // false
a.isEquivalent(to: b) // true
```

``URI/normalized()``は、比較に使う正規化した形を返します。スキームとホストを小文字にし、エンコードの表記を揃えます。絶対URIでは、ドットセグメント（`.`と`..`）も取り除きます。`https`の`:443`のような、スキームごとの既定のポートは取り除きません。

```swift
URI("HTTP://Example.COM/a/./b/../c/%7euser").normalized().asString
// "http://example.com/a/c/~user"
```

## パーセントエンコード

URIの構成要素ごとに、エンコードが必要な文字は異なります。``URI/percentEncode(_:component:)``で、対象の構成要素を指定してエンコードします。

```swift
URI.percentEncode("a b/c?", component: .pathSegment)   // "a%20b%2Fc%3F"
URI.percentDecode("a%20b%2Fc")                         // "a b/c"
URI.percentDecode("%E3%81")                            // nil（UTF-8として不正）
```

## ファイル URI

ローカルのファイルのパスと、`file:`のURIを相互に変換できます。

```swift
let uri: URI = URI.file("/tmp/my file.txt")
uri.asString     // "file:///tmp/my%20file.txt"
uri.isFileURI    // true
uri.filePath     // /tmp/my file.txt
```

``URI/filePath``は、ローカルのファイルを指すURIだけを変換します。ほかのホストを指すURIでは`nil`を返します。ホストが`localhost`のものは、ローカルとして扱います。

```swift
URI("file://localhost/etc/hosts").filePath   // /etc/hosts
URI("file://server/share/a.txt").filePath    // nil
```

``FilePath``からは``FilePath/uri``で変換できます。相対パスは、カレントディレクトリを基準に絶対パスにしてから変換します。詳しくは<doc:UsingFilePath>を参照してください。

## Topics

### URIの型

- ``URI``
- ``URI/Authority``
- ``URI/QueryItem``
- ``URI/Component``
- ``URIQuery``
