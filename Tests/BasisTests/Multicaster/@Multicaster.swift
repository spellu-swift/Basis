@testable import Basis


@Suite struct MulticasterTests {

	/// 受信した値を記録する。
	final class Recorder<Value : Sendable> : Sendable {

		let values: Barrier<[Value]>
		= .init([])

		func append(
			_ value: Value,
		) {
			values.write {
				$0.append(value)

				return .through
			}
		}

		var recorded: [Value] {
			values.read {
				.ok($0)
			}
		}

	}


	@Test func 購読した順に通知する() {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<String>
		= .init()

		for name in ["a", "b", "c"] {
			multicaster.subscribe { value in
				recorder.append("\(name)\(value)")
			}
		}

		multicaster.send(1)
		multicaster.send(2)

		#expect(recorder.recorded == ["a1", "b1", "c1", "a2", "b2", "c2"])
	}


	@Test func 引数なしのsendで通知する() {
		let multicaster: Multicaster<Void>
		= .init()
		let recorder: Recorder<Int>
		= .init()

		multicaster.subscribe {
			recorder.append(1)
		}

		multicaster.send()

		#expect(recorder.recorded == [1])
	}


	@Test func hasSubscribersは購読者の有無を返す() {
		let multicaster: Multicaster<Int>
		= .init()

		#expect(multicaster.hasSubscribers == false)

		let token: CancellableToken
		= multicaster.subscribe { _ in }

		#expect(multicaster.hasSubscribers == true)

		token.cancel()

		#expect(multicaster.hasSubscribers == false)
	}


	@Test func cancelした購読者には通知しない() {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<String>
		= .init()

		let tokenA: CancellableToken
		= multicaster.subscribe { recorder.append("a\($0)") }
		multicaster.subscribe { recorder.append("b\($0)") }

		multicaster.send(1)
		tokenA.cancel()
		multicaster.send(2)

		#expect(recorder.recorded == ["a1", "b1", "b2"])
	}


	@Test func cancelを2回呼んでもキャンセル処理は1回だけ呼ばれる() {
		let recorder: Recorder<Int>
		= .init()
		let token: CancellableToken
		= .init { recorder.append(1) }

		token.cancel()
		token.cancel()

		#expect(recorder.recorded == [1])
	}


	@Test func autoCancelしたトークンを破棄すると解除される() {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<Int>
		= .init()

		do {
			let token: CancellableToken
			= multicaster
				.subscribe { recorder.append($0) }
				.autoCancel()

			multicaster.send(1)

			withExtendedLifetime(token) {}
		}

		multicaster.send(2)

		#expect(recorder.recorded == [1])
		#expect(multicaster.hasSubscribers == false)
	}


	@Test func autoCancelしないトークンを破棄しても解除されない() {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<Int>
		= .init()

		multicaster.subscribe { recorder.append($0) }

		multicaster.send(1)
		multicaster.send(2)

		#expect(recorder.recorded == [1, 2])
		#expect(multicaster.hasSubscribers == true)
	}


	@Test func トークンはMulticasterを保持しない() {
		weak var weakMulticaster: Multicaster<Int>?
		let token: CancellableToken

		do {
			let multicaster: Multicaster<Int>
			= .init()

			weakMulticaster = multicaster
			token = multicaster.subscribe { _ in }
		}

		#expect(weakMulticaster == nil)

		token.cancel()
	}


	@Test func 購読者の中で購読と解除をしてもデッドロックしない() {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<String>
		= .init()
		let tokens: Barrier<[CancellableToken]>
		= .init([])

		let token: CancellableToken
		= multicaster.subscribe { value in
			recorder.append("outer\(value)")

			let inner: CancellableToken
			= multicaster.subscribe { recorder.append("inner\($0)") }

			tokens.write {
				$0.append(inner)

				return .through
			}
		}

		multicaster.send(1)
		token.cancel()
		multicaster.send(2)

		#expect(recorder.recorded == ["outer1", "inner2"])
	}


	@Test func 複数のスレッドから同時に購読と送信と解除ができる() async {
		let multicaster: Multicaster<Int>
		= .init()
		let recorder: Recorder<Int>
		= .init()

		let keeper: CancellableToken
		= multicaster.subscribe { recorder.append($0) }

		await withTaskGroup(of: Void.self) { group in
			for index in 0 ..< 100 {
				group.addTask {
					let token: CancellableToken
					= multicaster.subscribe { _ in }

					multicaster.send(index)
					token.cancel()
				}
			}
		}

		#expect(recorder.recorded.sorted() == Array(0 ..< 100))
		#expect(multicaster.hasSubscribers == true)

		keeper.cancel()

		#expect(multicaster.hasSubscribers == false)
	}

}
