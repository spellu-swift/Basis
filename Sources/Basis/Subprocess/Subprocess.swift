#if canImport(Darwin) || canImport(Glibc)
import Libc


/// 起動した子プロセス。
///
/// 入力の書き込みと出力の待機は、別のスレッドから同時に行える。
/// `wait`は呼び出したスレッドをブロックする。待機は1つのプロセスにつき1回だけ行う。
public final class Subprocess : Sendable {

	init(
		pid: pid_t,
		inFd: Int32,
		outFd: Int32,
		errFd: Int32,
	) {
		self.pid = pid
		self.inFd = .init(inFd)
		self.outFd = outFd
		self.errFd = errFd
	}

	deinit {
		closeInput()
		close(outFd)
		close(errFd)
	}

	let pid: pid_t
	/// 入力を閉じたら -1
	private let inFd: Barrier<Int32>
	let outFd: Int32
	let errFd: Int32

	@inlinable
	public func write(
		_ string: String,
	) {
		write(string.asBytes)
	}

	@inlinable
	public func write(
		_ binary: Binary,
	) {
		write(binary.asBytes)
	}

	public func write(
		_ bytes: [UInt8],
	) {
		inFd.atomic {
			guard $0 != -1 else { return }

			Libc.write($0, bytes, bytes.count)
		}
	}

	public func closeInput() {
		inFd.atomic {
			guard $0 != -1 else { return }

			close($0)
			$0 = -1
		}
	}

	@inlinable
	public func input(
		_ string: String
	) -> Self {
		input(string.asBytes)
	}

	@inlinable
	public func input(
		_ binary: Binary,
	) -> Self {
		input(binary.asBytes)
	}

	public func input(
		_ bytes: [UInt8],
	) -> Self {
		write(bytes)
		closeInput()

		return self
	}

	// MARK: イベント

	enum InternalEvent {
		case output(UnsafeRawBufferPointer)
		case error(UnsafeRawBufferPointer)
		case terminated(TerminationStatus)
	}

	///
	/// プロセスの完了を待機し、実行結果を返す。
	///
	public func wait(
		timeout: Double? = nil,
	) throws -> Result {
		let output: BinaryWriter = .init()
		let error: BinaryWriter = .init()

		let status: TerminationStatus
		= try wait(
			timeout: timeout,
		) { event in
			switch event {
			case .output(let buffer):
				output.write(buffer)

			case .error(let buffer):
				error.write(buffer)

			case .terminated:
				break
			}
		}

		return Result(
			output: output.asBinary,
			error: error.asBinary,
			status: status,
		)
	}

	func wait(
		timeout: Double? = nil,
		onEvent: (InternalEvent) -> Void,
	) throws -> TerminationStatus {
		let buffer = Buffer.allocate(capacity: 1024 * 4)

		try readOutputs(
			timeout: timeout,
			buffer: buffer,
			onEvent: onEvent,
		)

		let status: TerminationStatus
		= try waitProcess()

		onEvent(.terminated(status))

		return status
	}

	func read(
		fd: Int32,
		buffer: Buffer,
		totalBytes: Int,
	) throws -> UnsafeRawBufferPointer? {
		buffer.reallocate(capacity: totalBytes)

		let readBytes: Int = Libc.read(
			fd,
			buffer.pointer,
			totalBytes
		)

		guard
			readBytes >= 0
		else { throw POSIXError.system }

		if readBytes == 0 {
			return nil
		} else {
			return .init(
				start: buffer.pointer,
				count: readBytes
			)
		}
	}

	func waitProcess() throws -> TerminationStatus {
		try Self.waitForProcess(pid: pid)
	}

	static func waitForProcess(
		pid: pid_t,
		waiter: (pid_t, UnsafeMutablePointer<Int32>, Int32) -> pid_t = {
			waitpid($0, $1, $2)
		}
	) throws -> TerminationStatus {
		var status: Int32 = 0
		while waiter(pid, &status, 0) == -1 {
			if errno == EINTR { continue }
			throw POSIXError.system(errno)
		}
		return try .init(waitStatus: status)
	}
}
#endif
