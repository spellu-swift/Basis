# Multicaster

`Multicaster` は、ひとつの送信元から複数の受信者へイベントを届けるための型です。
送信元は購読者が何人いるかを気にせずに `send` を呼び、購読者はそれぞれ
`subscribe` で受け取る処理を登録します。

```swift
import Basis

let downloaded: Multicaster<String>
= .init()

downloaded.subscribe { fileName in
	print("ダウンロード完了:", fileName)
}

downloaded.send("report.pdf")
// ダウンロード完了: report.pdf
```


## 購読する

`subscribe(_:)` に、イベントを受け取るクロージャを渡します。
戻り値の `CancellableToken` は、購読をやめるときに使います。

```swift
let token: CancellableToken
= downloaded.subscribe { fileName in
	print(fileName)
}
```

購読をやめる予定がなければ、トークンは捨ててかまいません。
捨てても購読は続きます（後述の「購読をやめる」を参照）。


## 送信する

`send(_:)` に値を渡すと、すべての購読者に届きます。

```swift
downloaded.send("image.png")
```

### 値を持たないイベント

型引数を `Void` にすると、引数なしの `send()` を使えます。

```swift
let reloaded: Multicaster<Void>
= .init()

reloaded.subscribe {
	print("再読み込みしました")
}

reloaded.send()
```

### 複数の値を送る

複数の値を送りたいときは、タプルや構造体を型引数にします。

```swift
let progressed: Multicaster<(fileName: String, ratio: Double)>
= .init()

progressed.subscribe { fileName, ratio in
	print(fileName, ratio)
}

progressed.send((fileName: "report.pdf", ratio: 0.5))
```


## 購読をやめる

購読をやめる方法は2つあります。

### 明示的にやめる

トークンの `cancel()` を呼びます。呼んだ後に始まる `send` では、そのクロージャは呼ばれません。
`cancel()` は何度呼んでもかまいません。

```swift
let token: CancellableToken
= downloaded.subscribe { print($0) }

token.cancel()
```

### トークンの破棄と同時にやめる

`autoCancel()` を付けておくと、トークンが破棄されたときに購読をやめます。
画面やオブジェクトの寿命に合わせて購読したいときに便利です。

```swift
final class DownloadView {

	let token: CancellableToken

	init(
		downloaded: Multicaster<String>,
	) {
		token = downloaded
			.subscribe { fileName in
				print(fileName)
			}
			.autoCancel()
	}

}
```

`DownloadView` が破棄されると `token` も破棄され、購読が終わります。

> **注意**: `autoCancel()` を付けない場合、トークンを捨てても購読は続きます。
> Combine の `AnyCancellable` は破棄すると購読をやめるので、それとは逆です。


## 購読者がいるか調べる

`hasSubscribers` で、購読者がいるかどうかを調べられます。
イベントの値を作るのに手間がかかる場合、購読者がいなければ作らずに済ませられます。

```swift
if downloaded.hasSubscribers {
	downloaded.send(makeExpensiveDescription())
}
```


## 動作の保証

- **購読した順に呼ばれます。** 先に購読したクロージャから順に呼ばれます。
- **`send` を呼んだスレッドで、その場で呼ばれます。** `send` は、すべての購読者の
  処理が終わってから戻ります。
- **複数のスレッドから同時に使えます。** `Multicaster` と `CancellableToken` は
  `Sendable` です。購読・送信・購読の解除を、どのスレッドから同時に行ってもかまいません。
- **購読や解除は、次の `send` から反映されます。** `send` は、呼ばれた時点の購読者に
  届けます。送信の途中で購読や解除をしても、その送信には影響しません。
  別のスレッドで送信している最中に `cancel()` した場合も、その送信では呼ばれることがあります。
- **購読者の中で購読や解除をしてもかまいません。** デッドロックはしません。
- **トークンは `Multicaster` を保持しません。** `Multicaster` が破棄されると、
  購読もすべてなくなります。その後にトークンの `cancel()` を呼んでも問題ありません。


## 注意点

### 購読するクロージャは `@Sendable`

購読者は、`send` を呼んだスレッドで実行されます。そのため、購読するクロージャは
`@Sendable` でなければなりません。外の変更可能な状態を直接書き換えることはできないので、
`Sendable` な型を通して受け渡してください。

### 時間のかかる処理

購読者の処理が終わるまで `send` は戻りません。時間のかかる処理は、
購読者の中で `Task` を起動して行ってください。

```swift
downloaded.subscribe { fileName in
	Task {
		await upload(fileName)
	}
}
```

### メインアクターで受け取る

UI の更新など、メインアクターで処理したい場合は、購読者の中で
メインアクターに切り替えます。

```swift
downloaded.subscribe { fileName in
	Task { @MainActor in
		label.text = fileName
	}
}
```

`send` を呼ぶのが必ずメインアクターだとわかっている場合は、
`MainActor.assumeIsolated` を使うと、切り替えを待たずにその場で処理できます。

```swift
downloaded.subscribe { fileName in
	MainActor.assumeIsolated {
		label.text = fileName
	}
}
```

`MainActor.assumeIsolated` は、メインアクター以外から呼ばれるとプログラムが停止します。


## API 一覧

### Multicaster

| API | 説明 |
|---|---|
| `init()` | 購読者のいない `Multicaster` を作る。 |
| `subscribe(_:) -> CancellableToken` | イベントを受け取るクロージャを登録する。 |
| `send(_:)` | すべての購読者に値を送る。 |
| `send()` | 型引数が `Void` のとき、すべての購読者にイベントを送る。 |
| `hasSubscribers` | 購読者がいるかどうか。 |

### CancellableToken

| API | 説明 |
|---|---|
| `cancel()` | 購読をやめる。2回目以降は何もしない。 |
| `autoCancel() -> Self` | トークンが破棄されたときに購読をやめるようにする。 |
| `init(cancel:)` | 任意のキャンセル処理を持つトークンを作る。`cancel()` で一度だけ呼ばれる。 |
