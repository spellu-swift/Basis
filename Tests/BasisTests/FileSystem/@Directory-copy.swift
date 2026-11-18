@testable import Basis


@Test
func directory_copy_subpath_and_deep_descendants() throws {
	try sandbox(name: #function) { directory in
		let source = directory["source"]
		try source.createDirectory()
		try source.path["root.txt"].file.save("root")
		try source.path["a/b/c/d/e/f/deep.txt"].file.save("deep")
		try source.path["broken-link"].file.createSymlink(of: "missing".asFilePath)

		let destination = directory.path["destination"]
		try directory.copy("source", to: destination)

		#expect(try destination["root.txt"].file.load().asString == "root")
		#expect(try destination["a/b/c/d/e/f/deep.txt"].file.load().asString == "deep")
		#expect(FileStatus(at: destination["broken-link"].expanded, followLink: false)?.symlink == true)
		#expect(try POSIX.readlink(at: destination["broken-link"].expanded) == "missing")
	}
}


@Test
func directory_copy_respects_recursive_depth() throws {
	try sandbox(name: #function) { directory in
		let source = directory["source"]
		try source.createDirectory()
		try source.path["root.txt"].file.save("root")
		try source.path["a/child.txt"].file.save("child")
		try source.path["a/b/grandchild.txt"].file.save("grandchild")

		let shallow = directory.path["shallow"]
		try source.copy(to: shallow, recursive: false)
		#expect(try shallow["root.txt"].file.load().asString == "root")
		#expect(shallow["a"].directory.exists)
		#expect(shallow["a/child.txt"].file.exists == false)

		let limited = directory.path["limited"]
		try source.copy(to: limited, recursive: .depth(2))
		#expect(try limited["a/child.txt"].file.load().asString == "child")
		#expect(limited["a/b/grandchild.txt"].file.exists == false)
	}
}
