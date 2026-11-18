@testable import Basis


private enum TemporaryDirectoryTestError : Error {
	case failed
}


@Test
func temporary_directory_is_empty_unique_and_removed_recursively() throws {
	var path: FilePath?
	let result = try Directory.withTemporary(prefix: "BasisTest") { directory in
		path = directory.path
		#expect(directory.path.isAbsolute)
		#expect(directory.path.fileName.hasPrefix("BasisTest-"))
		#expect(try directory.list().isEmpty)
		try directory[file: "child/a/b/data"].save("temporary")

		try Directory.withTemporary(prefix: "BasisTest", in: directory.parent) { other in
			#expect(other.path != directory.path)
			#expect(directory.exists)
		}

		return 42
	}

	#expect(result == 42)
	#expect(path?.directory.exists == false)
}


@Test
func temporary_directory_cleanup_preserves_body_error() throws {
	try sandbox(name: #function) { parent in
		var path: FilePath?

		#expect(throws: TemporaryDirectoryTestError.self) {
			try Directory.withTemporary(in: parent) { directory in
				path = directory.path
				#expect(directory.parent.path.realized == parent.path.realized)
				try directory[file: "child/data"].save("temporary")
				throw TemporaryDirectoryTestError.failed
			}
		}

		#expect(path?.directory.exists == false)
		let entries = try parent.list()
		#expect(entries.isEmpty)
	}
}
