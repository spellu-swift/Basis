

// MARK: [UInt8] + Path


extension Array where Element == UInt8 {
	
	@inlinable
	public func save(
		to path: FilePath,
		atomic: Bool = false,
	) throws -> Void {
		try path.file.save(asBinary, atomic: atomic)
	}
	
}


// MARK: Binary + Path


extension Binary {
	
	@inlinable
	public func save(
		to path: FilePath,
		atomic: Bool = false,
	) throws -> Void {
		try path.file.save(self, atomic: atomic)
	}
	
}


// MARK: String + Path


extension String {
	
	@inlinable
	public var asFilePath: FilePath {
		FilePath(self)
	}

	@inlinable
	public func save(
		to path: FilePath,
		atomic: Bool = false,
	) throws -> Void {
		try path.file.save(self, atomic: atomic)
	}
	
}
