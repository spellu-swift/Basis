# struct URI

Basisの基盤型として、**RFC 3986に準拠したURI操作を中心に、便利機能を段階的に追加する**方針で整理する。

実装方針は以下の通り。

- Swift Regexは使う。

## 機能仕様

### 1. 文字列変換・解析

| API | 機能 | 優先度 |
|---|---|---|
| `static func parse(_ string: String)` | URI参照を解析して生成 | 必須 |
| `asString` | URI文字列への変換 | 必須 |
| `description` | `CustomStringConvertible` | 実装済み |
| `isAbsolute` | スキームを持つURIか判定 | 必須 |
| `isRelative` | 相対参照か判定 | 必須 |

### 2. Percent Encoding

| API | 機能 | 優先度 |
|---|---|---|
| `static func percentEncode(_:component:)` | コンポーネント別のエンコード | 必須 |
| `static func percentDecode(_:)` | Percent Encodingのデコード | 必須 |
| `enum Component` | エンコード対象の種類 | 必須 |

```swift
extension URI {

	public enum Component {
		case userInfo
		case host
		case path
		case pathSegment
		case query
		case fragment
	}

	public static func percentEncode(
		_ string: String,
		component: Component
	) -> String

	public static func percentDecode(
		_ string: String
	) -> String?
}
```

エンコードはUTF-8単位で行う。

`percentDecode` は不正な `%` エスケープや不正なUTF-8を検出できるよう、Optionalを返す。

### 3. 相対参照の解決

| API | 機能 | 優先度 |
|---|---|---|
| `resolved(against:)` | 基底URIから相対参照を解決 | 必須 |
| `removingDotSegments()` | `.` と `..` を除去 | 必須 |
| `relative(to:)` | 基底URIからの相対参照を生成 | 実装済み |

```swift
let base = URI("https://example.com/a/b")!
let relative = URI("../cat")!

let result = relative.resolved(against: base)

// https://example.com/cat
```

`resolved(against:)` はRFC 3986 Section 5に準拠する。

戻り値は `URI?` とし、基底URIがスキームを持たない場合は `nil` を返す。
基底URIのfragmentは継承せず、参照側のfragmentを使用する。
スキームが基底と一致していても、参照にスキームがあれば絶対URIとして解決する。

`relative(to:)` の署名は `func relative(to base: URI) -> URI?` とする。

```swift
let base = try URI.parse("https://example.com/a/b")
let target = try URI.parse("https://example.com/cat")

target.relative(to: base)?.asString
// ../cat
```

- 対象と基底の両方にスキームが必要とし、どちらかが相対参照なら `nil` を返す。
- 対象のドットセグメントを除去したURIへ、`resolved(against:)` で再解決できる参照を返す。
- schemeとauthorityは構造的に比較し、Percent Encodingの表記は保持する。正規化したい場合は呼び出し側で先に正規化する。
- schemeとauthorityが一致する場合、空パスによる継承、共通ディレクトリからの相対パス、対象のパスをそのまま使う参照の順に検討する。
- 基底の最後のパス要素は、末尾が `/` の場合を除きファイル名として扱う。末尾の `/`、空のパス要素、エンコードされた区切り文字を区別する。
- queryとfragmentの未指定・空を保持する。対象のqueryが未指定なら、基底のqueryを誤って継承しない参照を生成する。
- パスだけで表せない場合、authorityがあれば `//authority` から始まる参照を返す。schemeが異なる場合や相対参照で表せない場合は、対象のドットセグメント除去後の絶対URIを返す。
- 元のURIは変更しない。文字数が最短の参照になることは保証しない。

### 4. 正規化

| API | 機能 | 優先度 |
|---|---|---|
| `normalized()` | RFC 3986に基づく正規化 | 必須 |
| `normalize()` | 自身を変更する正規化 | 低 |
| `isEquivalent(to:)` | 正規化を考慮した等価性判定 | 実装済み |

```swift
let uri = URI("HTTP://Example.COM/a/../b/%7Euser")!

uri.normalized().asString
// http://example.com/b/~user
```

`Hashable` の `==` は構造的な一致とし、URIとしての等価性判定は別メソッドにする。

`normalized()` は構文に基づく以下の正規化を行う。

- schemeとhostを小文字化する。
- Percent Encodingの16進数を大文字化し、unreserved文字だけをデコードする。
- スキームを持つURIのpathからドットセグメントを除去する。
- 相対参照のドットセグメントは、基底URIとの位置関係を保持するため残す。相対参照は解決後に正規化する。
- 既定ポートの削除、空パスの`/`への置換など、スキーム固有の正規化は行わない。

`normalize()` は `normalized()` の結果で自身を置き換える。

`isEquivalent(to:)` の署名は `func isEquivalent(to other: URI) -> Bool` とする。
両者に `normalized()` を適用して構造的に比較し、元のURIは変更しない。
既定ポートやIPv6アドレスの表記揺れの統一、query項目の並べ替えなど、
`normalized()` の範囲外の同一視は行わない。fragmentの違いと、query・fragment・authorityの空と未指定も区別する。
相対参照同士も比較できるが、基底URIからの解決は行わない。

### 5. Authority関連

| API | 機能 | 優先度 |
|---|---|---|
| `Authority.init(userInfo:host:port:)` | Authority生成 | 必須 |
| `Authority.init?(_:)` | Authority文字列の解析 | 必須 |
| `Authority.asString` | Authority文字列への変換 | 必須 |
| `Authority.portNumber` | 数値ポートの取得 | 便利 |
| `URI.host` | `authority?.host` のショートカット | 便利 |

```swift
extension URI.Authority {

	public var portNumber: Int? {
		port.flatMap(Int.init)
	}
}
```

IPv6アドレス（IPv4埋め込みを含む）とIPvFutureに対応し、角括弧をhostに保持する。
IPv6のゾーン識別子はRFC 3986の範囲外なので受け付けない。
portは空文字列と未指定を区別し、桁数や値の上限を構文解析時には制限しない。
`portNumber` はIntへ変換できない場合に `nil` を返す。

### 6. Query操作

| API | 機能 | 優先度 |
|---|---|---|
| `queryItems` | クエリを名前・値の配列に変換 | 便利 |
| `appendingQueryItem(name:value:)` | クエリ項目を追加 | 便利 |
| `removingQueryItems(named:)` | 指定した名前の項目を削除 | 実装済み |

```swift
extension URI {

	public struct QueryItem: Hashable, Sendable {
		public var name: String
		public var value: String?
	}

	public var queryItems: [QueryItem] { get }
}
```

重複キーと順序を保持する。

`QueryItem.init(name:value:)` は未エンコードの名前と値を受け取る。valueの既定値は `nil`。
`queryItems` は `&` と最初の `=` で分割してからPercent Encodingをデコードし、
値なしと空の値を区別する。`+`は空白に変換しない。
空のqueryと未指定のqueryは空配列になり、空でないquery中の空項目は保持する。
不正なUTF-8の項目はデコードせず、エンコードされた文字列を返す。
`appendingQueryItem(name:value:)` は名前と値のunreserved以外の文字をエンコードして末尾に追加する。
既存のqueryは書き換えない。

`removingQueryItems(named:)` の署名は `func removingQueryItems(named name: String) -> URI` とする。
未エンコードの名前を受け取り、`queryItems` と同じデコード規則で名前が一致する項目をすべて削除する。
名前は大文字・小文字を区別し、`+`は空白に変換しない。不正なUTF-8の名前はエンコードされた文字列のまま比較する。
残る項目の順序・重複・値の有無・Percent Encodingの表記をそのまま保持する。
全項目を削除した場合はqueryを `nil` にする。元からqueryが未指定または空なら、その状態を保持する。
空項目が残る場合はそれも保持し、例えば `?a=1&` から `a` を削除した結果は `?` になる。
query以外の構成要素と元のURIは変更しない。

`queryItems` はRFC 3986の基本構文には含まれないため、Web向け拡張機能として扱う。

### 7. Path操作

| API | 機能 | 優先度 |
|---|---|---|
| `pathSegments` | パスをセグメントに分解 | 便利 |
| `appendingPathComponent(_:)` | パス要素を追加 | 便利 |
| `deletingLastPathComponent()` | 最後のパス要素を削除 | 便利 |
| `lastPathComponent` | 最後のパス要素を取得 | 便利 |

```swift
let uri = URI("https://example.com/docs")!

uri.appendingPathComponent("cat.png")
// https://example.com/docs/cat.png
```

`pathSegments` は先頭のルート区切りを除き、空のセグメントと末尾の区切りを保持する。
`lastPathComponent` は末尾の区切りを無視し、空パスとルートでは空文字列を返す。
どちらもPercent Encodingされた文字列を返し、`%2F`をパス区切りにしない。
`appendingPathComponent(_:)` は未エンコードの単一要素を受け取り、要素内の`/`もエンコードする。
`deletingLastPathComponent()` は末尾の区切りを無視して最後の要素を削除し、親ディレクトリの末尾に`/`を残す。
Path操作はqueryとfragmentを保持する。
Path操作・ドット除去・正規化の結果がauthorityなしで`//`から始まる場合は `/.` を付ける。
相対パスの先頭要素がコロンを含む場合は `./` を付ける。文字列化後の再解析でも構成要素を保持するための処理である。


### 8. File URI

| API | 機能 | 優先度 |
|---|---|---|
| `static file(_:)` | ローカルファイルURI生成 | 実装済み |
| `filePath` | ローカルファイルパス取得 | 便利 |
| `isFileURI` | fileスキームか判定 | 便利 |

`file(_:)` はRFC 8089に従い、空のauthorityを設定する。

StringとFilePathを受け取り、未エンコードのパスをUTF-8でエンコードする。
相対パスは現在の作業ディレクトリを基準に絶対パスへ変換する。
`filePath` の型は `FilePath?` とする。fileスキームかつ絶対パスで、authorityが未指定・空・localhostの場合に返す。
ユーザー情報やポートを持つauthority、リモートホスト、不正なUTF-8、NUL、エンコードされた`/`は `nil` になる。
`isFileURI` はスキームの大文字・小文字を区別しない。

### 9. 生成・解析の契約

- `init?(_:)` と `parse(_:) throws -> URI` はRFC 3986のURI参照を検証する。空の参照も有効とする。
- `parse` は不正な入力に `GeneralError.invalidFormat` を投げる。
- URI文字列中の未エンコードの非ASCII文字、空白、制御文字、不正なPercent Encodingは拒否する。
- Percent Encodingされたバイト列はUTF-8としての検証をせず保持する。UTF-8の検証は `percentDecode` で行う。
- 構成要素を指定するinitializerと各プロパティへの代入は、エンコード済みの文字列を検証せず保持する。
- `asString` は各構成要素をそのまま連結し、二重エンコードしない。
- `percentEncode` は生の文字列を受け取り、`%`も `%25` に変換する。host対象はreg-nameの許可文字を使う。
- Codableは構成要素を持つオブジェクトとして保存する。文字列形式への変更は行わない。


## テストケース

以下を網羅すること。

- 絶対URIと相対参照
- 空のauthorityとauthorityなし
- 空のqueryとqueryなし
- 空のfragmentとfragmentなし
- IPv4、IPv6、IPvFuture
- Percent Encodingを含むURI
- 不正なURIの拒否
- 解析→文字列化→再解析の往復
- 相対参照の生成と再解決の往復、scheme・authorityの違いによるフォールバック
- query継承の解除、空パス・末尾のスラッシュ・空セグメントの保持
- 正規化の範囲に基づく同値性と、構造的な等値性との区別
- query項目の全件削除、重複キー、エンコードされた名前、残る項目の表記保持
