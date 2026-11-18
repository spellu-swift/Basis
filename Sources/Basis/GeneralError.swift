

/// よく使われる一般的な汎用エラー
public enum GeneralError : ProgramError {
	
	case notSupported
	case notImplemented
	case invalidEncoding(String)
	case invalidFormat(String)
	case invalidTimeZone(String)
	case unexpectedValue(String)
	case endOfStream(String)
	case timedOut
	
	case developping(String)
	
}


extension GeneralError {
	
	public enum Fatal {
		public static func noImplementation(
			_ message: String? = nil,
			file: StaticString = #file,
			line: UInt = #line
		) -> Never {
			fatalError(message ?? "No implementation", file: file, line: line)
		}
		
		public static func abstractMethodNotImplemented(
			_ message: String? = nil,
			_ functionName: String = #function
		) -> Never {
			fatalError(message ?? "Abstract method \(functionName) is not implemented.")
		}
	}
	
}

