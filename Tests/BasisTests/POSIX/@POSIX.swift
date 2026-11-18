@testable import Basis


@Suite struct POSIXTests {

@Test
	func user() {
		#expect(
			POSIX.user(name: "root")?.pw_dir.asString == "/var/root"
		)
	}
		
	@Test
	func copyDirectory() throws {
		try sandbox(name: #function) { directory in
			let destination: FilePath = directory.path
			
			try POSIX.copyDirectory(
				at: fixtureDirectory.path.expanded,
				to: destination.expanded,
			)
			
			check(
				at: destination,
				type: .directory, symlink: false,
			)
			
			check(
				at: destination.appending("file"),
				type: .file, symlink: false,
			)
			check(
				at: destination.appending("hello"),
				type: .file, symlink: false,
			)
			
			check(
				at: destination.appending("directory"),
				type: .directory, symlink: false,
			)
			check(
				at: destination.appending("directory/child"),
				type: .file, symlink: false,
			)
			check(
				at: destination.appending("directory/subdirectory"),
				type: .directory, symlink: false,
			)
			check(
				at: destination.appending("directory/subdirectory/child"),
				type: .file, symlink: false,
			)
			
			check(
				at: destination.appending("symlinks"),
				type: .directory, symlink: false,
			)
			check(
				at: destination.appending("symlinks/directory"),
				type: .directory, symlink: true,
			)
			check(
				at: destination.appending("symlinks/file"),
				type: .file, symlink: true,
			)
			check(
				at: destination.appending("symlinks/same-dir"),
				type: .file, symlink: true,
			)
		}
	}
	
	@Test
	func symlink() throws {
		try sandbox(name: #function) { directory in
			let path = directory.path["xxx"].expanded

			try POSIX.createSymlink(at: path, of: "yyy")
			#expect(try POSIX.readlink(at: path) == "yyy")

			try POSIX.unlink(at: path)
			#expect(FileStatus(at: path, followLink: false) == nil)
		}
	}

	@Test
	func gethostname() throws {
		print(try POSIX.gethostname())
	}
	
}


private func check(
	at path: FilePath,
	type: FileType?,
	symlink: Bool,
) {
	let fs: FileStatus? = .init(at: path, followLink: true)

	#expect(fs != nil)
	#expect(fs?.type == type)
	#expect(fs?.symlink == symlink)
}
