

// MARK: Binary + URI


extension Binary {
	
	public func save(
		to uri: URI,
		atomic: Bool = false,
	) throws -> Void {
		guard
			let path = uri.filePath
		else { throw GeneralError.invalidFormat(uri.asString) }

		try File(at: path).save(self, atomic: atomic)
	}
	
}


// MARK: Path + URI


extension FilePath {
	
	@inlinable
	public var uri: URI {
		.file(asString)
	}
	
}


// MARK: File + URI


extension File {
	
	@inlinable
	public var uri: URI {
		.file(path.asString)
	}
	
}


// MARK: Directory + URI


extension Directory {
	
	@inlinable
	public var uri: URI {
		.file(path.asString)
	}
	
}

