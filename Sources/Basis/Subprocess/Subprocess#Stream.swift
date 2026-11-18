#if canImport(Darwin) || canImport(Glibc)
import Libc

extension Subprocess {

	public enum Event: Sendable {

		case output([UInt8])
		case error([UInt8])
		case terminated(TerminationStatus)

	}

	public struct Stream: AsyncSequence {

		let stream: AsyncThrowingStream<Event, any Error>

		public typealias AsyncIterator = AsyncThrowingStream<
			Event, any Error
		>.AsyncIterator

		public typealias Element = Event

		public func makeAsyncIterator()
			-> AsyncThrowingStream<Event, any Error>
			.AsyncIterator
		{
			stream.makeAsyncIterator()
		}

	}

	/// 終了状態と待機エラーを失わないAsyncThrowingStreamを作成する。
	/// for try await event in process.stream {} でイベントを処理できます。
	///
	/// 待機は専用のスレッドで行うため、Swift Concurrencyのスレッドをブロックしない。
	public var stream: Stream {
		let (stream, continuation) = AsyncThrowingStream<
			Event, any Error
		>.makeStream()

		let started: Int32 = Self.detachThread {
			do {
				_ = try self.wait { event in
					switch event {
					case .output(let buffer):
						continuation.yield(
							.output(
								buffer
									.asBytes
							),
						)

					case .error(let buffer):
						continuation.yield(
							.error(
								buffer
									.asBytes
							),
						)

					case .terminated(let status):
						continuation.yield(
							.terminated(
								status
							),
						)
					}
				}
			} catch {
				continuation.finish(throwing: error)
				return
			}

			continuation.finish()
		}

		if started != 0 {
			continuation.finish(throwing: POSIXError.system(started))
		}

		return .init(
			stream: stream,
		)
	}

	/// 処理を専用のスレッドで実行する。スレッドは処理の終了とともに終わる。
	/// - Returns: pthread_createの結果。0なら成功
	private static func detachThread(
		_ body: @escaping @Sendable () -> Void,
	) -> Int32 {
		final class Context : Sendable {
			let body: @Sendable () -> Void

			init(_ body: @escaping @Sendable () -> Void) {
				self.body = body
			}
		}

		let unmanaged: Unmanaged<Context> = .passRetained(Context(body))

#if canImport(Darwin)
		var thread: pthread_t?
#else
		var thread: pthread_t = .init()
#endif

		let result: Int32 = pthread_create(
			&thread,
			nil,
			{ context in
#if canImport(Darwin)
				let context: UnsafeMutableRawPointer = context
#else
				let context: UnsafeMutableRawPointer = context!
#endif

				Unmanaged<Context>.fromOpaque(context).takeRetainedValue().body()

				return nil
			},
			unmanaged.toOpaque(),
		)

		if result == 0 {
#if canImport(Darwin)
			pthread_detach(thread!)
#else
			pthread_detach(thread)
#endif
		}
		else {
			unmanaged.release()
		}

		return result
	}

}

#endif
