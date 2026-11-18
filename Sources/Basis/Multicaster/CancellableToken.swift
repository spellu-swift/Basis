

///
/// キャンセル機能を持つトークン。
/// - 明示的なキャンセル。cancel()メソッドを呼ぶ。
/// - 暗黙的なキャンセル。autoCancel()メソッドを呼んでおくと、トークンの参照カウンタが0になった時点でcancel()が呼ばれる。
/// - キャンセル処理は一度だけ呼ばれる。複数のスレッドから同時にcancel()を呼んでもよい。
///
public final class CancellableToken : Sendable {

	public typealias Cancel = @Sendable () -> Void

	struct State : Sendable {
		var cancel: Cancel?
		var automatic: Bool
	}

	public init(
		cancel: @escaping Cancel,
	) {
		state = .init(
			.init(
				cancel: cancel,
				automatic: false,
			)
		)
	}

	deinit {
		let automatic: Bool
		= state.read {
			.ok($0.automatic)
		}

		if automatic {
			cancel()
		}
	}

	let state: Barrier<State>

	public func cancel(
	) {
		let cancel: Cancel?
		= state.atomic {
			let cancel: Cancel?
			= $0.cancel

			$0.cancel = nil

			return cancel
		}

		cancel?()
	}

	public func autoCancel(
	) -> Self {
		state.write {
			$0.automatic = true

			return .through
		}

		return self
	}

}
