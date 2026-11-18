#if canImport(Glibc)
@testable import Basis
import Libc


struct SubprocessPollTests {

	private func descriptors(
	) -> [pollfd] {
		[
			.init(fd: 0, events: .init(POLLIN), revents: 0),
		]
	}

	@Test func 待ち時間をミリ秒へ切り上げる() {
		#expect(Subprocess.pollMilliseconds(nil) == -1)
		#expect(Subprocess.pollMilliseconds(0) == 0)
		#expect(Subprocess.pollMilliseconds(0.0001) == 1)
		#expect(Subprocess.pollMilliseconds(1.5) == 1500)
		#expect(Subprocess.pollMilliseconds(-1) == 0)
		#expect(Subprocess.pollMilliseconds(.infinity) == .max)
		#expect(Subprocess.pollMilliseconds(.nan) == 0)
	}

	@Test func 割り込まれたら再試行する() throws {
		var descriptors: [pollfd] = descriptors()
		var attempts: Int = 0

		try Subprocess.waitReadable(
			&descriptors,
			timeout: nil,
		) { _, count, milliseconds in
			#expect(count == 1)
			#expect(milliseconds == -1)

			attempts += 1

			if attempts == 1 {
				errno = EINTR

				return -1
			}

			return 1
		}

		#expect(attempts == 2)
	}

	@Test func 再試行では残りの時間だけ待つ() throws {
		var descriptors: [pollfd] = descriptors()
		var waits: [Int32] = []

		try Subprocess.waitReadable(
			&descriptors,
			timeout: 60,
		) { _, _, milliseconds in
			waits.append(milliseconds)

			if waits.count == 1 {
				usleep(20_000)
				errno = EINTR

				return -1
			}

			return 1
		}

		#expect(waits.count == 2)
		#expect(waits[1] < waits[0])
		#expect(waits[1] > 0)
	}

	@Test func 待ち時間が尽きたらtimedOutを送出する() {
		var descriptors: [pollfd] = descriptors()

		#expect(throws: GeneralError.timedOut) {
			try Subprocess.waitReadable(
				&descriptors,
				timeout: 1,
			) { _, _, _ in
				0
			}
		}
	}

	@Test func 割り込み以外の失敗は送出する() {
		var descriptors: [pollfd] = descriptors()

		#expect(throws: POSIXError.system(ENOMEM)) {
			try Subprocess.waitReadable(
				&descriptors,
				timeout: nil,
			) { _, _, _ in
				errno = ENOMEM

				return -1
			}
		}
	}

	@Test func 不正なディスクリプタは送出する() {
		// どのプロセスでも開いていない番号なので、deinitのcloseも影響しない。
		let process: Subprocess = .init(
			pid: 0,
			inFd: -1,
			outFd: 1_000_000,
			errFd: -1,
		)

		#expect(throws: POSIXError.system(EBADF)) {
			try process.wait(timeout: 1)
		}
	}

}
#endif
