import Libc


public struct POSIXError : ProgramError {

	public init(
		code: Int32,
		name: String,
		debugDescription: String,
	) {
		self.code = code
		self.name = name
		self.debugDescription = debugDescription
	}
	
	public let code: Int32
	public let name: String
	public let debugDescription: String
	
	/// 読みやすいメッセージ
	public var readableMessage: String {
		"\(name)(\(code)): \(debugDescription)"
	}
	
}


extension POSIXError {

	@inlinable
	public static func system(
		_ errorCode: Int32,
	) -> Self {
		let posixErrorCode: POSIXErrorCode? = .init(
			rawValue: errorCode
		)
		
		return .init(
			code: errorCode,
			name: errorName(posixErrorCode),
			debugDescription: errorDescription(posixErrorCode)
		)
	}

	@inlinable
	public static var system: Self {
		system(errno)
	}

	public static func errorName(
		_ code: POSIXErrorCode?,
	) -> String {
		switch code {
			case .none: // 0
				return ""
			case .EPERM: // 1
				return "EPERM"
			case .ENOENT: // 2
				return "ENOENT"
			case .ESRCH: // 3
				return "ESRCH"
			case .EINTR: // 4
				return "EINTR"
			case .EIO: // 5
				return "EIO"
			case .ENXIO: // 6
				return "ENXIO"
			case .E2BIG: // 7
				return "E2BIG"
			case .ENOEXEC: // 8
				return "ENOEXEC"
			case .EBADF: // 9
				return "EBADF"
			case .ECHILD: // 10
				return "ECHILD"
			case .EDEADLK: // 11, was EAGAIN.
				return "EDEADLK"
			case .ENOMEM: // 12
				return "ENOMEM"
			case .EACCES: // 13
				return "EACCES"
			case .EFAULT: // 14
				return "EFAULT"
			case .ENOTBLK: // 15
				return "ENOTBLK"
			case .EBUSY: // 16
				return "EBUSY"
			case .EEXIST: // 17
				return "EEXIST"
			case .EXDEV: // 18
				return "EXDEV"
			case .ENODEV: // 19
				return "ENODEV"
			case .ENOTDIR: // 20
				return "ENOTDIR"
			default:
				return "???\(code!.rawValue)"
		}
	}

	public static func errorDescription(
		_ code: POSIXErrorCode?,
	) -> String {
		code
			.flatMap{ strerror($0.rawValue) }
			.map{ String(cString: $0) }
		?? ""
	}
	
}


//extension POSIXError {
//	
//	
//	public static func check(
//		_ condition: Bool
//	) throws {
//		guard condition
//		else { throw system }
//	}
//	
//	
//	public static func check<Result>(
//		noneZero result: Result
//	) throws -> Result where Result : BinaryInteger {
//		guard result != 0
//		else { throw system }
//		return result
//	}
//	
//	
//	public static func check<Result>(
//		_ result: Result?
//	) throws -> Result {
//		guard let result
//		else { throw system }
//		
//		return result
//	}
//	
//	
//}

