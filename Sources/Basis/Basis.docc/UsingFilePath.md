# FilePath の使い方

ファイルシステムのパスを、文字列ではなく値として扱う。

## Overview

``FilePath``は、`/Users/alice/Documents/report.txt`のようなUNIX形式のパスを表す値型です。パスの分解・結合・拡張子の操作・相対パスの解決を、文字列操作をせずに行えます。

`FilePath`はパスの文字列を扱うだけで、ファイルシステムには触れません。存在しないパスも作れますし、パスを作っただけではファイルは作られません。ファイルの読み書きには``File``を、ディレクトリの操作には``Directory``を使います。

## パスを作る

文字列リテラルからそのまま作れます。

```swift
let path: FilePath = "/Users/alice/Documents/report.tar.gz"
```

文字列の変数からは、イニシャライザで作ります。複数の要素を渡すと、区切りの`/`を補って結合します。

```swift
let name: String = "report.txt"
let path: FilePath = FilePath(name)

let log: FilePath = FilePath("/var", "log", "app.log")
// /var/log/app.log
```

作るときに、連続する`/`は1つにまとめます。`..`は取り除きません。

```swift
FilePath("/a//b/c/")    // /a/b/c/
FilePath("/a/b/../c")   // /a/b/../c
```

パスの文字列が必要なときは``FilePath/asString``を使います。

```swift
path.asString   // "/Users/alice/Documents/report.tar.gz"
```

## パスを分解する

```swift
let path: FilePath = "/Users/alice/Documents/report.tar.gz"

path.fileName                   // "report.tar.gz"
path.fileNameWithoutExtension   // "report.tar"
path.extension                  // "gz"
path.dottedExtension            // ".gz"
path.parent                     // /Users/alice/Documents/
path.names                      // ["Users", "alice", "Documents", "report.tar.gz"]
path.isAbsolute                 // true
```

``FilePath/parent``は、末尾に`/`が付いたディレクトリのパスとして返します。

ディレクトリの部分を取り出すには``FilePath/basePath``（`FilePath`）か``FilePath/baseName``（`String`）を使います。`baseName`は、名前と違ってファイル名ではなく、ディレクトリの部分を返すことに注意してください。

```swift
path.basePath   // /Users/alice/Documents
path.baseName   // "/Users/alice/Documents"
```

祖先のディレクトリは``FilePath/ancestors``で、近い順ではなくルートに近い順に得られます。

```swift
FilePath("/a/b/c").ancestors   // [/a, /a/b]
```

### 複数のドットを含む拡張子

`report.tar.gz`のような名前では、どこからを拡張子とみなすかを``FilePath/ExtensionSeparatePosition``で指定します。

```swift
path.extension(position: .last)       // "gz"（既定）
path.extension(position: .last(2))    // "tar.gz"（後ろから2つ）
path.extension(position: .first)      // "tar.gz"（最初のドットから後ろ）

path.fileNameWithoutExtension(position: .first)   // "report"
```

## パスを組み立てる

`appending(_:)`で、後ろに要素を追加します。`nil`を渡した要素は無視されます。

```swift
let logs: FilePath = "/var/log"

logs.appending("app", "today.log")        // /var/log/app/today.log

let subdirectory: String? = nil
logs.appending("app", subdirectory, "today.log")   // /var/log/app/today.log
```

添字でも同じように書けます。

```swift
logs["app", "today.log"]   // /var/log/app/today.log
```

ファイル名や拡張子の置き換え、ファイル名への前置き・後置きもできます。

```swift
let path: FilePath = "/Users/alice/Documents/report.tar.gz"

path.replacing(fileName: "summary.txt")   // /Users/alice/Documents/summary.txt
path.replacing(extension: "bz2")          // /Users/alice/Documents/report.tar.bz2
FilePath("/tmp/README").replacing(extension: "md")   // /tmp/README.md

FilePath("/photos/cat.jpg").insert(prefix: "small-", suffix: "@2x")
// /photos/small-cat@2x.jpg
```

## 相対パスを解決する

相対パスを基準のパスに対して解決するには`resolved(relativeTo:as:)`を使います。基準がディレクトリかファイルかを``FilePath/Kind``で指定します。

```swift
let child: FilePath = "child"

// 基準のディレクトリの中
child.resolved(relativeTo: "/work/project", as: .directory)
// /work/project/child

// 基準のファイルと同じディレクトリの中
child.resolved(relativeTo: "/work/project/document.txt", as: .file)
// /work/project/child
```

`as:`を省略すると、基準の末尾の`/`で判断します。末尾に`/`があればディレクトリ、なければファイルとして扱います。意図しない結果を避けるため、迷うときは明示してください。

```swift
child.resolved(relativeTo: "/work/project/")   // /work/project/child
child.resolved(relativeTo: "/work/project")    // /work/child
```

解決のときの規則は次のとおりです。

- 絶対パスは、基準に関係なくそのまま返します。
- `.`は取り除きますが、`..`は残します。シンボリックリンクをたどるパスでは、`..`を字句的に取り除くと意味が変わることがあるためです。
- ファイルシステムは調べません。存在しないパスも解決できます。

```swift
FilePath("/etc/hosts").resolved(relativeTo: "/work")
// /etc/hosts

FilePath("../shared/x").resolved(relativeTo: "/work/project/", as: .directory)
// /work/project/../shared/x
```

基準と相対パスから、直接作ることもできます。

```swift
FilePath(relativeTo: "/work/project/", "src/main.swift")
// /work/project/src/main.swift
```

### 絶対パスにする

カレントディレクトリを基準に絶対パスにするには``FilePath/absoluted``を使います。基準を指定するには`absoluted(relativeTo:as:)`を使います。この場合、基準は絶対パスでなければなりません。

```swift
FilePath("docs/a.txt").absoluted
// カレントディレクトリが /work なら /work/docs/a.txt
```

### `..`を取り除く・リンクをたどる

`..`の扱いは、目的に応じて使い分けます。

- ``FilePath/normalized``: 字句的に`..`と`.`を取り除きます。ファイルシステムは調べません。
- ``FilePath/realpath``: シンボリックリンクをたどった実体のパスを返します。パスが存在しなければ`nil`です。
- ``FilePath/realized``: `realpath`が得られればそれを、得られなければ元のパスを返します。

```swift
FilePath("/a/b/../c").normalized   // /a/c
```

### 基準からの相対パスにする

```swift
FilePath("/work/project/src/main.swift").relatived(base: "/work/project")
// src/main.swift
```

## ホームディレクトリと環境変数を展開する

パスの中の`~`と環境変数は、作ったときには展開しません。展開した文字列は``FilePath/expanded``で得られます。ファイルを操作するAPIは、内部で展開してから使います。

```swift
FilePath("~/notes.txt").expanded
// "/Users/alice/notes.txt"
```

環境変数の代わりに、値を指定して展開することもできます。展開はPOSIXのシェルと同じ規則で、変数名の大文字・小文字を区別し、未定義の変数は空になります。

```swift
FilePath("$ROOT/${App}/log").expanded(values: ["ROOT": "/srv", "App": "web"])
// "/srv/web/log"
```

## ファイルとディレクトリを操作する

パスから``File``や``Directory``を得て、読み書きや一覧の取得をします。

```swift
let path: FilePath = "/tmp/example.txt"

try path.file.save("hello")
let text: String = try path.file.load().decode()

path.status?.type       // .file。存在しなければ status が nil
path.fileExisting       // 通常のファイルとして存在すれば File、なければ nil
path.directoryExisting  // ディレクトリとして存在すれば Directory、なければ nil
```

パスのままで、移動・コピー・削除もできます。

```swift
try path.copy(to: "/tmp/example-copy.txt")
try path.move(to: "/tmp/renamed.txt")
try FilePath("/tmp/renamed.txt").delete()
```

### ファイルの一部を読む

大きなファイルの先頭や途中だけが要るときは、``FileReader``を使います。ファイルを1度開き、位置を指定して読みます。読んだバイト列は``BinaryReader``で解釈できます。

```swift
let reader: FileReader = try .init(path.file)

reader.size  // 開いたときの大きさ

// 先頭の4バイト
let magic: Binary = try reader.read(at: 0, count: 4)

// 16バイト目から、リトルエンディアンの16ビット整数を2つ
let fields: BinaryReader = .init(try reader.read(at: 16, count: 4))
let type: UInt16 = try fields.readUInt16(.little)
let machine: UInt16 = try fields.readUInt16(.little)
```

ファイルの終わりを越える分は読みません。返る長さが短くなるだけで、エラーにはなりません。全体を読むなら``File/load()``を使います。

## 権限を変更する

権限は``FilePermissions``で表します。8進数のリテラル、対象ごとの指定、`ls -l`と同じ表記の文字列のどれでも書けます。

```swift
try path.setPermissions(0o644)
try path.setPermissions(.init(owner: .readWrite, group: .read, other: .read))
try path.setPermissions(FilePermissions("rw-r--r--")!)

// 今の権限をもとに一部だけ変更する（chmod u+x）
try path.updatePermissions { $0.insert(.ownerExecute) }

path.file.permissions?.description  // "rwxr--r--"。存在しなければ permissions が nil
```

シンボリックリンクの場合は、リンク先の権限を変更します。

## URI に変換する

ファイルのURIは``FilePath/uri``で得られます。空白などはパーセントエンコードされます。詳しくは<doc:UsingURI>を参照してください。

```swift
FilePath("/tmp/my file.txt").uri.asString
// "file:///tmp/my%20file.txt"
```

## Topics

### パスの型

- ``FilePath``
- ``FilePath/Kind``
- ``FilePath/ExtensionSeparatePosition``
- ``FilePathComponents``

### ファイルシステム

- ``File``
- ``FileReader``
- ``Directory``
- ``FileStatus``
- ``FilePermissions``
