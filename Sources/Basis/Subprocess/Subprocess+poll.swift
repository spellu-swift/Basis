#if canImport(Glibc)
import Libc


extension Subprocess {

	/// 1回の読み込みの上限。Linuxのパイプの既定の容量に合わせる。
	private static let readCapacity: Int = 64 * 1024

	/// 標準出力と標準エラー出力が両方ともEOFになるまで読み込む。
	///
	/// `timeout`はDarwinの実装と同じく、次の出力を待つ時間の上限。
	func readOutputs(
		timeout: Double?,
		buffer: Buffer,
		onEvent: (InternalEvent) -> Void,
	) throws {
		var descriptors: [pollfd] = [
			.init(fd: outFd, events: .init(POLLIN), revents: 0),
			.init(fd: errFd, events: .init(POLLIN), revents: 0),
		]

		while descriptors.contains(where: { $0.fd != -1 }) {
			try Self.waitReadable(
				&descriptors,
				timeout: timeout,
			)

			for index in descriptors.indices {
				let descriptor: pollfd = descriptors[index]

				guard
					descriptor.revents != 0
				else { continue }

				guard
					descriptor.revents & .init(POLLNVAL) == 0
				else { throw POSIXError.system(EBADF) }

				guard
					let bytes = try read(
						fd: descriptor.fd,
						buffer: buffer,
						totalBytes: Self.readCapacity,
					)
				else {
					// pollは負の値のディスクリプタを無視する。
					descriptors[index].fd = -1

					continue
				}

				if descriptor.fd == outFd {
					onEvent(.output(bytes))
				}
				else {
					onEvent(.error(bytes))
				}
			}
		}
	}

	/// いずれかのディスクリプタが読み込める状態になるまで待つ。
	///
	/// シグナルで中断されたら、残りの時間で待ち直す。
	static func waitReadable(
		_ descriptors: inout [pollfd],
		timeout: Double?,
		poller: (UnsafeMutablePointer<pollfd>, nfds_t, Int32) -> Int32 = {
			Libc.poll($0, $1, $2)
		},
	) throws {
		let deadline: Double?
		= timeout.map { monotonicSeconds + $0 }

		while true {
			let milliseconds: Int32
			= pollMilliseconds(deadline.map { $0 - monotonicSeconds })

			let result: Int32
			= descriptors.withUnsafeMutableBufferPointer {
				poller($0.baseAddress!, .init($0.count), milliseconds)
			}

			if result > 0 {
				return
			}

			if result == 0 {
				throw GeneralError.timedOut
			}

			let error: Int32 = errno

			guard
				error == EINTR
			else { throw POSIXError.system(error) }
		}
	}

	/// 秒をpollの待ち時間に変換する。nilは無期限を表す。
	///
	/// 切り捨てると短い待ち時間が0になるので、切り上げる。
	static func pollMilliseconds(
		_ seconds: Double?,
	) -> Int32 {
		guard
			let seconds
		else { return -1 }

		let milliseconds: Double = (seconds * 1000).rounded(.up)

		return .init(max(0, min(milliseconds, Double(Int32.max))))
	}

	private static var monotonicSeconds: Double {
		var time: timespec = .init()

		clock_gettime(CLOCK_MONOTONIC, &time)

		return Double(time.tv_sec) + Double(time.tv_nsec) / 1_000_000_000
	}

}

#endif
