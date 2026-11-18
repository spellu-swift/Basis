@testable import Basis
import Libc


@Suite struct FilePartialIOTests {

	@Test
	func read_retries_interruptions_and_short_reads() throws {
		let input: [UInt8] = [1, 2, 3, 4, 5]
		var position = 0
		var calls = 0

		let result = try File.readAll(reservingCapacity: 10) { pointer, capacity in
			calls += 1
			if calls == 1 || calls == 3 {
				errno = EINTR
				return -1
			}
			let count = min(2, input.count - position)
			#expect(capacity >= count)
			for index in 0..<count {
				pointer.storeBytes(of: input[position + index], toByteOffset: index, as: UInt8.self)
			}
			position += count
			return count
		}

		#expect(result.asBytes == input)
		#expect(calls == 6)
	}


	@Test
	func write_retries_interruptions_and_short_writes() throws {
		let input: Binary = [1, 2, 3, 4, 5]
		var output: [UInt8] = []
		var calls = 0

		try File.writeAll(input) { pointer, remaining in
			calls += 1
			if calls == 1 || calls == 3 {
				errno = EINTR
				return -1
			}
			let count = min(2, remaining)
			output.append(contentsOf: UnsafeRawBufferPointer(start: pointer, count: count))
			return count
		}

		#expect(output == input.asBytes)
		#expect(calls == 5)
	}


	@Test
	func no_progress_and_permanent_errors_are_reported() {
		#expect(throws: POSIXError.system(EIO)) {
			try File.writeAll([1]) { _, _ in 0 }
		}
		#expect(throws: POSIXError.system(ENOSPC)) {
			try File.writeAll([1]) { _, _ in
				errno = ENOSPC
				return -1
			}
		}
		#expect(throws: POSIXError.system(EIO)) {
			try File.readAll { _, _ in
				errno = EIO
				return -1
			}
		}
	}


	@Test
	func empty_files_and_multiple_chunks_roundtrip() throws {
		try sandbox(name: #function) { directory in
			let file = directory[file: "data"]
			let bytes = (0..<200000).map { UInt8(truncatingIfNeeded: $0) }

			try file.save(Binary(bytes))
			#expect(try file.load().asBytes == bytes)

			try file.save(Binary([]))
			#expect(try file.load().asBytes.isEmpty)
		}
	}

	@Test
	func open_and_stat_retry_interruptions() {
		var calls = 0
		let result = File.retryInterrupted {
			calls += 1
			if calls < 3 {
				errno = EINTR
				return -1
			}
			return 7
		}

		#expect(result == 7)
		#expect(calls == 3)
	}
}
