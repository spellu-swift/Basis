#if canImport(Darwin) || canImport(Glibc)
@testable import Basis
import Libc


@Test
func subprocess_short_read_reports_actual_bytes() async throws {
	var fds: [Int32] = [-1, -1]
	#expect(Libc.pipe(&fds) == 0)

	let process = Subprocess(pid: 0, inFd: -1, outFd: fds[0], errFd: -1)
	let bytes: [UInt8] = [65]
	let written = bytes.withUnsafeBytes {
		Libc.write(fds[1], $0.baseAddress, $0.count)
	}
	Libc.close(fds[1])
	#expect(written == 1)

	let result = try process.readForShortReadTest(requested: 8)
	#expect(result == bytes)
	#expect(try process.readForShortReadTest(requested: 8) == nil)
}


private extension Subprocess {

	func readForShortReadTest(requested: Int) throws -> [UInt8]? {
		let buffer = Basis.Buffer.allocate(capacity: requested)

		return try read(fd: outFd, buffer: buffer, totalBytes: requested)?.asBytes
	}
}
#endif
