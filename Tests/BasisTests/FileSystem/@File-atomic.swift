@testable import Basis
import Libc
import Dispatch


@Test
func atomic_save_creates_replaces_and_preserves_permissions() throws {
	try Directory.withTemporary { directory in
		let file = directory[file: "nested/data"]
		try file.saveAtomically([1, 2, 3])
		#expect(try file.load().asBytes == [1, 2, 3])
		#expect(file.permissions == 0o600)

		try file.setPermissions(0o640)
		let oldHandle = open(file.path.asString, O_RDONLY | O_CLOEXEC)
		#expect(oldHandle >= 0)
		defer { close(oldHandle) }

		let bytes = (0..<200000).map { UInt8(truncatingIfNeeded: $0) }
		try file.saveAtomically(Binary(bytes))
		#expect(try file.load().asBytes == bytes)
		#expect(file.permissions == 0o640)

		// 開いていたファイルは以前の内容を保ち、保存先だけが置き換わる。
		let oldBytes = try File.readAll { Libc.read(oldHandle, $0, $1) }
		#expect(oldBytes.asBytes == [1, 2, 3])

		try file.saveAtomically(Binary([]))
		#expect(try file.load().asBytes.isEmpty)
		#expect(try file.parent.list().map(\.relativePath) == ["data"])
	}
}


@Test
func atomic_save_replaces_symlink_without_changing_target() throws {
	try Directory.withTemporary { directory in
		let target = directory[file: "target"]
		try target.save("original")
		let link = directory[file: "link"]
		try link.createSymlink(of: target.path)

		try link.saveAtomically(Binary("replacement"))

		#expect(try link.load().asString == "replacement")
		#expect(try target.load().asString == "original")
		#expect(FileStatus(at: link.path, followLink: false)?.symlink == false)
	}
}


@Test
func atomic_save_failure_preserves_existing_destination() throws {
	try Directory.withTemporary { directory in
		let destination = directory["destination"]
		try destination.createDirectory()
		try destination[file: "data"].save("original")

		#expect(throws: FileSystemError.self) {
			try File(at: destination.path).saveAtomically([1, 2, 3])
		}

		#expect(try destination[file: "data"].load().asString == "original")
		#expect(try directory.list().map(\.relativePath) == ["destination"])
	}
}


@Test
func atomic_save_parallel_writes_do_not_mix_contents() throws {
	try Directory.withTemporary { directory in
		let file = directory[file: "data"]
		let count = 200000
		try file.saveAtomically(Binary([UInt8](repeating: 0, count: count)))

		DispatchQueue.concurrentPerform(iterations: 8) { index in
			do {
				try file.saveAtomically(Binary([UInt8](repeating: UInt8(index), count: count)))
				let bytes = try file.load().asBytes
				#expect(bytes.count == count)
				#expect(bytes.allSatisfy { $0 == bytes.first })
			}
			catch {
				Issue.record(error)
			}
		}

		#expect(try directory.list().map(\.relativePath) == ["data"])
	}
}


@Test
func atomic_save_write_failure_keeps_original_and_removes_temporary_file() throws {
	try Directory.withTemporary { directory in
		let file = directory[file: "data"]
		try file.save("original")
		var calls = 0

		#expect(throws: POSIXError.system(ENOSPC)) {
			try file.saveAtomically([1, 2, 3], using: { handle, pointer, count in
				calls += 1
				if calls == 1 {
					return Libc.write(handle, pointer, min(count, 1))
				}

				errno = ENOSPC
				return -1
			})
		}

		#expect(calls == 2)
		#expect(try file.load().asString == "original")
		#expect(try directory.list().map(\.relativePath) == ["data"])
	}
}


@Test
func atomic_save_accepts_relative_path() throws {
	try Directory.withTemporary(in: Directory(at: ".")) { directory in
		let file: File = .init(at: "\(directory.path.fileName)/data")
		try file.saveAtomically([1, 2, 3])

		#expect(try directory[file: "data"].load().asBytes == [1, 2, 3])
	}
}
