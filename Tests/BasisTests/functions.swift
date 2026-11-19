import Basis
@_exported import UnitTesting




func sandbox(
	name: String,
	cleanup: Bool = true,
	perform: (Directory) throws -> Void
) throws {
	let directory: Directory
	= Backbone.temporaryDirectory["\(name)-\(UUID.new)"]
		.directory
	
	try directory.createDirectory()
	
	defer {
		if cleanup {
			try? directory.deleteDirectory(recursive: true)
		}
	}
	
	try perform(directory)
}
