#if canImport(Darwin)
import Libc


public final class KQueue {
	
	public init(
	) throws {
		let fd = kqueue()

		guard
			fd > 0
		else { throw POSIXError.system }
		
		self.fd = fd
	}
	
	deinit {
		close(fd)
	}
	
	let fd: Int32

	// SEE: https://github.com/mheily/libkqueue/blob/master/include/sys/event.h#L127

	public enum Descripter : Equatable {
		case read(Int32)   // file descripter
		case write(Int32)  // file descripter
		case aio(Int32)    // file descripter
		case vnode(Int32)  // file descripter ???
		case process(Int32)   // process id
		case signal(Int32) // SIGxxx
//		case timer = -7
//		case netdev = -8
//		case fs = -9
//		case lio = -10
//		case user = -11
//		case libkqueue = -12
		case unknown(Int16, UInt) // (filter, ident)
	}
	
	public enum Filter : Int16, Equatable {
		case read = -1
		case write = -2
		case aio = -3
		case vnode = -4
		case proc = -5
		case signal = -6
		case timer = -7
		case netdev = -8
		case fs = -9
		case lio = -10
		case user = -11
		case libkqueue = -12
	}
	
	public enum Action : Int32, Equatable {
		case add = 0x0001
		case delete = 0x0002
		case enable = 0x0004
		case disable = 0x0008
	}
	
	public enum Flags : Int32, Equatable {
		case oneshot = 0x0010
		case clear = 0x0020
		case receipt = 0x0040
		case dispatch = 0x0080
	}

	public func registerEvent(
		descripter: Descripter,
		action: Action,
		flags: Flags? = .none,
		fflags: UInt32 = 0,
		data: Int = 0,
		udata: UnsafeMutableRawPointer? = nil,
	) throws {
		let (filter, ident) = descripter.parse()

		try registerEvent(
			ident: ident,
			filter: filter,
			flags: numericCast(action.rawValue | (flags?.rawValue ?? 0)),
			fflags: fflags,
			data: data,
			udata: udata,
		)
	}

	public func registerEvent(
		ident: UInt,
		filter: Int16,
		flags: UInt16,
		fflags: UInt32 = 0,
		data: Int = 0,
		udata: UnsafeMutableRawPointer? = nil,
	) throws {
		var event = kevent(
			ident: ident,
			filter: filter,
			flags: flags,
			fflags: fflags,
			data: data,
			udata: udata,
		)
		
		let result: Int32 = kevent(fd, &event, 1, nil, 0, nil)
//		#print(#function, "kevent", result)

		guard
			result == 0
		else { throw POSIXError.system }
	}
	
	public func waitEvent(
		timeout: Double? = nil,
	) throws -> (Descripter, Int) {
		var event = kevent()
		
		let result: Int32

		if
			let timeout
		{
			var timeout: timespec = .init(
				.seconds(timeout),
			)
			
			result = kevent(fd, nil, 0, &event, 1, &timeout)
		}
		else {
			result = kevent(fd, nil, 0, &event, 1, nil)
		}
		
//		#print(#function, "kevent", result, event.ident, event.filter, event)

		if result == 0 {
			throw GeneralError.timedOut
		}
		else if result < 0 {
			throw POSIXError.system
		}

		return (
			.from(
				filter: event.filter,
				ident: event.ident,
			),
			event.data,
		)
	}

}


extension KQueue.Descripter {

	static func from(
		filter: Int16,
		ident: UInt,
	) -> Self {
		switch filter {
			case -1:
				.read(numericCast(ident))
			
			case -2:
				.write(numericCast(ident))
				
			case -3:
				.aio(numericCast(ident))
				
			case -4:
				.vnode(numericCast(ident))
				
			case -5:
				.process(numericCast(ident))
				
			case -6:
				.signal(numericCast(ident))

			default:
				.unknown(filter, ident)
		}
	}
	
	func parse(
	) -> (Int16, UInt) {
		switch self {
			case .read(let fd):
				(-1, numericCast(fd))

			case .write(let fd):
				(-2, numericCast(fd))
				
			case .aio(let fd):
				(-3, numericCast(fd))
				
			case .vnode(let fd):
				(-4, numericCast(fd))
				
			case .process(let pid):
				(-5, numericCast(pid))
				
			case .signal(let signal):
				(-6, numericCast(signal))
				
			case .unknown(let filter, let ident):
				(filter, ident)
		}
	}
	
}

// kqueueでファイルの状態を監視する
// https://laclefyoshi.hatenablog.com/entry/20110507/1304774708

#endif
