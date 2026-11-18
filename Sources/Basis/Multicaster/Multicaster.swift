

///
/// マルチキャスター
/// 1対多のイベント伝搬モデルを実装する。
/// - 購読者には、購読した順に通知する。
/// - 複数のスレッドから同時に購読・送信・解除できる。
///
public final class Multicaster<Parameter> : Sendable
where Parameter : Sendable {

	public typealias Perform = @Sendable (Parameter) -> Void

	typealias Key = UInt64

	struct Subscriber : Sendable {
		let key: Key
		let perform: Perform
	}

	struct State : Sendable {
		var lastKey: Key
		var subscribers: [Subscriber]
	}

	public init(
	) {
		state = .init(
			.init(
				lastKey: 0,
				subscribers: [],
			)
		)
	}

	let state: Barrier<State>

	/// 購読者がいるかどうか。
	public var hasSubscribers: Bool {
		state.read {
			.ok($0.subscribers.isNotEmpty)
		}
	}

	/// イベントを購読する。
	/// イベントがsendされるたびにperformが呼ばれます。
	@discardableResult
	public func subscribe(
		_ perform: @escaping Perform,
	) -> CancellableToken {
		let key: Key
		= state.atomic {
			$0.lastKey += 1

			let key: Key
			= $0.lastKey

			$0.subscribers.append(
				.init(
					key: key,
					perform: perform,
				)
			)

			return key
		}

		return CancellableToken { [weak self] in
			self?.unsubscribe(key)
		}
	}

	/// 空のイベントを送信する。
	public func send(
	) where Parameter == Void {
		send(())
	}

	/// 引数付きイベントを送信する。
	/// 購読者は、ロックの外で呼ばれる。そのため、購読者の中で購読・解除しても
	/// デッドロックしない。
	public func send(
		_ parameter: Parameter,
	) {
		let subscribers: [Subscriber]
		= state.read {
			.ok($0.subscribers)
		}

		for subscriber in subscribers {
			subscriber.perform(parameter)
		}
	}

	func unsubscribe(
		_ key: Key,
	) {
		state.write {
			$0.subscribers.removeAll {
				$0.key == key
			}

			return .through
		}
	}

}
