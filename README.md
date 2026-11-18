# Basis


## 動作環境

- Swift 6.0 以上（Swift 6 の言語モード）
- macOS 14 以上、iOS 17 以上


## BasisExperimental

`BasisExperimental` は実験的なコードのため、バージョン保証の対象外です。
マイナーやパッチの更新でも、予告なく変更・削除することがあります。
`Basis` 製品に含まれていますが、`import BasisExperimental` を書いたときだけ使えます。
使う場合は、`.exact(...)` などでバージョンを固定してください。


## コンソールコマンド

### 依存パッケージの更新
swift package update

### ビルド
swift build

### テスト
swift test --enable-code-coverage
swift test --enable-code-coverage --verbose

非機能テスト（計算量など）は、環境変数を指定したときだけ実行します。

BASIS_NONFUNCTIONAL_TESTS=1 swift test --filter NonFunctionalTests

### クリーン
swift package clean

## Subprocessの終了状態

`Result.status` は `Subprocess.TerminationStatus` です。
`exited(code:)` と `signaled(signal:)` を区別し、成功は `status.isSuccess`
（通常終了かつコード0）で判定します。従来の `Result.code` と
`Result(output:error:code:)` は、それぞれ `status` と
`Result(output:error:status:)` へ移行してください。

`asBinary` / `asString` は非ゼロ終了とシグナル終了の両方でエラーになります。
`process.stream` は `AsyncThrowingStream` となり、`for try await` で読みます。
終了イベントは `.terminated(status)`、待機の失敗はストリームのエラーです。
シグナル終了を `128 + signal` や `0` に変換することはありません。

`Subprocess` は actor ではなく `Sendable` なクラスで、`await` なしで呼びます。
`wait` は呼び出したスレッドをブロックします。`stream` は専用のスレッドで待機するので、
出力を読みながら `write` や `closeInput` を呼べます。

子プロセスは標準入出力以外のファイル記述子を暗黙に継承しません。
また、シグナルマスクを空にし、シグナル処理を既定に戻して起動します。

## SemanticVersion

[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)に従い、
`major.minor.patch` の3要素を必須とします。プレリリースとビルドメタデータを
保持し、プレリリースの比較では数値・ASCII・識別子の個数を使います。
等価判定・ハッシュ・比較は優先順位を表し、ビルドメタデータを無視します。
文字列表現とCodableではビルドメタデータも保持します。

各コア要素は必須の `SemanticVersion.Number` へ変更しました。
整数リテラル、UInt、検証付きの10進数文字列から生成でき、桁数に上限を
設けません。構成要素は不変で、バージョンの構築とparseは不正形式を拒否します。
旧Optionalのminor/patchと、変更可能なプロパティは廃止しました。

```swift
let version = try SemanticVersion.parse("1.2.3-alpha.1+001")
let next = version.patchIncremented // 1.2.4
```

コアの加算は下位要素をリセットし、プレリリース・ビルドメタデータを取り除きます。
