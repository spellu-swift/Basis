

// MARK: Path + File


extension FilePath {
	
	@inlinable
	public var file: File {
		.init(at: _path)
	}
	
}


// MARK: [UInt8] + File


extension Array where Element == UInt8 {
		
	@inlinable
	public func save(
		to file: File,
		atomic: Bool = false,
	) throws -> Void {
		try file.save(asBinary, atomic: atomic)
	}
	
}


// MARK: Binary + File


extension Binary {
		
	@inlinable
	public func save(
		to file: File,
		atomic: Bool = false,
	) throws -> Void {
		try file.save(self, atomic: atomic)
	}
	
}


// MARK: String + File


extension String {
		
	@inlinable
	public func save(
		to file: File,
		atomic: Bool = false,
	) throws -> Void {
		try file.save(self, atomic: atomic)
	}
		
}


