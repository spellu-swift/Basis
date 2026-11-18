import Libc


extension POSIX {

#if canImport(Darwin) || canImport(Glibc)
	public static let GLOB_DEFAULT_FLAGS =
	GLOB_TILDE | GLOB_BRACE | GLOB_MARK
#else
	public static let GLOB_DEFAULT_FLAGS =
	GLOB_TILDE | GLOB_MARK
#endif
	
	/// ディレクトリ下のエントリをパターンマッチする
	public static func glob(
		directory: String? = nil,
		pattern: String,
		flags: Int32 = GLOB_DEFAULT_FLAGS,
	) throws -> [String] {
		var cwd: String? = nil
		
		if let directory = directory {
			cwd = getcwd()
			
			try chdir(directory)
		}

		defer {
			if let cwd = cwd {
				try? chdir(cwd)
			}
		}
		
		var context = glob_t()
		
		try POSIX.checkError(
			Libc.glob(pattern, flags, nil, &context) == 0
		)
		
		var paths: [String] = []
		
		for i in 0..<Int(context.gl_pathc) {
			paths.append(
				String(cString: context.gl_pathv[i]!)
			)
		}
		
		globfree(&context)
		
		return paths
	}

	/// ファイル名マッチング
	public static func match(
		_ string: String,
		pattern: String,
		flags: Int32 = FNM_PATHNAME,
	) -> Bool {
		Libc.fnmatch(
			pattern,
			string,
			flags
		) == 0
	}

}
