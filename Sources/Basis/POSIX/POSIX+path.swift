

extension POSIX {
	
	public static var path: [FilePath] {
		environment["PATH"]?
			.split(separator: ":")
			.map{FilePath($0.asString)}
		?? []
	}
	
	@inlinable
	public static func searchFile(
		in directories: [FilePath] = POSIX.path,
		_ name: String,
	) -> FilePath? {
		searchFile(
			in: directories,
			name,
			limit: 1,
		).first
	}
	
	public static func searchFile(
		in directories: [FilePath] = POSIX.path,
		_ name: String,
		limit: Int = Int.max,
	) -> [FilePath] {
		var result: [FilePath] = []
		
		for directory in directories {
			let filePath = directory[name]
			
			if filePath.file.exists {
				result += filePath
				
				if result.count >= limit {
					break
				}
			}
		}
		
		return result
	}
	
}
