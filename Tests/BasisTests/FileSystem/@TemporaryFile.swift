@testable import Basis


private enum TemporaryFileTestError : Error {
	case failed
}


@Test
func temporary_file_is_empty_unique_and_removed() throws {
	var paths: [FilePath] = []
	let result = try File.withTemporary(prefix: "BasisTest", suffix: ".txt") { file in
		paths.append(file.path)
		#expect(file.path.isAbsolute)
		#expect(file.path.fileName.hasPrefix("BasisTest-"))
		#expect(file.path.fileName.hasSuffix(".txt"))
		#expect(try file.load().asBytes.isEmpty)

		try File.withTemporary(prefix: "BasisTest", suffix: ".txt", in: file.parent) { other in
			paths.append(other.path)
			#expect(file.path != other.path)
			#expect(file.exists)
			try other.save("temporary")
		}

		return 42
	}

	#expect(result == 42)
	#expect(paths.allSatisfy { !$0.file.exists })
}


@Test
func temporary_file_cleanup_preserves_body_error() throws {
	try sandbox(name: #function) { directory in
		var path: FilePath?

		#expect(throws: TemporaryFileTestError.self) {
			try File.withTemporary(in: directory) { file in
				path = file.path
				#expect(file.parent.path.realized == directory.path.realized)
				try file.delete()
				throw TemporaryFileTestError.failed
			}
		}

		#expect(path?.file.exists == false)
	}
}


@Test
func temporary_file_is_removed_after_body_throws() throws {
	try sandbox(name: #function) { directory in
		#expect(throws: TemporaryFileTestError.self) {
			try File.withTemporary(in: directory) { file in
				try file.save("temporary")
				throw TemporaryFileTestError.failed
			}
		}

		let entries = try directory.list()
		#expect(entries.isEmpty)
	}
}


@Test
func temporary_file_accepts_relative_directory() throws {
	let expectedParent = FilePath(POSIX.getcwd()).realized

	try File.withTemporary(in: Directory(at: ".")) { file in
		#expect(file.path.isAbsolute)
		#expect(file.parent.path.realized == expectedParent)
		try file.save("temporary")
	}
}
