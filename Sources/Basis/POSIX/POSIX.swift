import Libc


public class POSIX {

	public static let PATH_MAX: Int = .init(Libc.PATH_MAX)

}


extension POSIX {
	
	public static func checkError(
		_ condition: Bool,
	) throws {
		guard condition
		else { throw POSIXError.system }
	}
	
	public static func checkError<Result>(
		_ result: Result,
		test: (Result) -> Bool,
	) throws where Result : BinaryInteger {
		guard test(result)
		else { throw POSIXError.system }
	}
	
	public static func checkError<Result>(
		_ result: Result?,
	) throws -> Result {
		guard let result
		else { throw POSIXError.system }
		
		return result
	}
	
}


extension POSIX {
	
	public static var environment: [String : String] {
		var values: [String : String] = [:]
		var index: Int = 0
		
		while
			let line: UnsafeMutablePointer<CChar> = Libc.environ.advanced(by: index).pointee
		{
			let line = String(cString: line)
			
			let parts = line.split(separator: "=", maxSplits: 1)
			values[String(parts[0])] = parts.count == 2 ? String(parts[1]) : ""
			
			index += 1
		}
		
		return values
	}
	
	public static var temporaryDirectory: String {
#if canImport(Darwin)
		if let value = config(name: _CS_DARWIN_USER_TEMP_DIR) {
			return value
		}
#endif
		
		if let value = environment["TMPDIR"] {
			return value
		}
		
#if os(Android)
		// Bionic uses /data/local/tmp/ as temporary directory. TMPDIR is rarely
		// defined.
		return "/data/local/tmp/"
#else
		return "/var/tmp/"
#endif
	}
	
	public static func config(
		name: Int32,
	) -> String? {
		let safe_confstr = { (name: Int32, buf: UnsafeMutablePointer<Int8>?, len: Int) -> Int in
			// POSIX moment of weird: confstr() is one of those annoying APIs which
			// can return zero for both error and non-error conditions, so the only
			// way to disambiguate is to put errno in a known state before calling.
			errno = 0
			let result = confstr(name, buf, len)
			
			// result == 0 is only error if errno is not zero. But, if there was an
			// error, bail; all possible errors from confstr() are Very Bad Things.
			let err = errno // only read errno once in the failure case.
			precondition(result > 0 || err == 0, "Unexpected confstr() error: \(err)")
			
			// This is extreme paranoia and should never happen; this would mean
			// confstr() returned < 0, which would only happen for impossibly long
			// sizes of value or long-dead versions of the OS.
			assert(result >= 0, "confstr() returned impossible result: \(result)")
			
			return result
		}
		
		let length: Int = safe_confstr(name, nil, 0)
		
		guard length > 0
		else { return nil }
		
		let buffer: UnsafeMutablePointer<CChar> = .allocate(capacity: length)
		
		defer {
			buffer.deallocate()
		}

		let finalLength = safe_confstr(name, buffer, length)
		
		assert(length == finalLength, "Value of conf changed?")
		
		return String(cString: buffer)
	}
	
}
