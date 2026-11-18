

// MARK: Path + Directory


extension FilePath {
		
	@inlinable
	public var directory: Directory {
		.init(at: _path)
	}
	
}



