#if os(macOS) || canImport(Glibc)
@testable import Basis
import Libc


struct SubprocessStartFailureTests {

	/// パイプの反対側の複製を持ち、親が使う側が閉じられたかを確かめる。
	///
	/// ディスクリプタの番号は、並列に動く他のテストに再利用されるので使わない。
	private final class Probe {

		init(
			failingAt failure: Int? = nil,
		) {
			self.failure = failure
		}

		deinit {
			for descriptor in descriptors {
				close(descriptor.fd)
			}
		}

		private let failure: Int?
		private var descriptors: [pollfd] = []

		var count: Int {
			descriptors.count
		}

		/// 入力、出力、エラー出力の順に呼ばれる。
		func makePipe(
			_ fds: inout [Int32],
		) -> Int32 {
			if descriptors.count == failure {
				errno = EMFILE

				return -1
			}

			let result: Int32 = pipe(&fds)

			#expect(result == 0)

			// 親は入力の書き込み側と、出力の読み込み側を使う。
			let isInput: Bool = descriptors.isEmpty
			let descriptor: pollfd = .init(
				fd: dup(isInput ? fds[0] : fds[1]),
				events: .init(isInput ? POLLIN : POLLOUT),
				revents: 0,
			)

			#expect(!isClosed(descriptor))

			descriptors.append(descriptor)

			return result
		}

		/// 親が使う側がすべて閉じられるのを待つ。
		///
		/// 並列に起動した子が、exec前の短い間だけ複製を持つことがあるので待つ。
		func waitUntilClosed(
		) -> Bool {
			for _ in 0..<100 {
				if descriptors.allSatisfy(isClosed) {
					return true
				}

				usleep(10_000)
			}

			return false
		}

		private func isClosed(
			_ descriptor: pollfd,
		) -> Bool {
			var descriptor: pollfd = descriptor

			poll(&descriptor, 1, 0)

			return descriptor.revents & .init(POLLHUP | POLLERR) != 0
		}

	}

	@Test func 起動に失敗したら親が使うパイプも閉じる() {
		let probe: Probe = .init()

		#expect(throws: POSIXError.system(ENOENT)) {
			try Subprocess.execute(
				["/bin/sh"],
				workingDirectoryPath: "/<missing>",
				environment: [:],
				pipeMaker: probe.makePipe,
			)
		}

		#expect(probe.count == 3)
		#expect(probe.waitUntilClosed())
	}

	@Test(arguments: 0..<3)
	func パイプの作成に失敗したら作成済みのパイプを閉じる(
		_ failure: Int,
	) {
		let probe: Probe = .init(failingAt: failure)

		#expect(throws: POSIXError.system(EMFILE)) {
			try Subprocess.execute(
				["/bin/sh"],
				workingDirectoryPath: "/",
				environment: [:],
				pipeMaker: probe.makePipe,
			)
		}

		#expect(probe.count == failure)
		#expect(probe.waitUntilClosed())
	}

}
#endif
