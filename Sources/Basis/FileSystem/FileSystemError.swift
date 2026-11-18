

public enum FileSystemError : ProgramError {
	
	case missing(File)
	case invalidType(File)
	case decodeFailed(File)
	case io(File)
	/// ほかのプロセスがロックを持っている。値はロックファイル。
	case locked(File)

}


