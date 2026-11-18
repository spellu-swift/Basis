import Libc


extension POSIX {

#if canImport(Darwin)
	public typealias time_t = __darwin_time_t
#elseif canImport(Glibc)
	public typealias time_t = Glibc.time_t
#elseif canImport(Musl)
	public typealias time_t = Musl.time_t
#endif
	
	public static func gettime(
	) -> timespec {
		var time: timespec = .init()

		clock_gettime(CLOCK_REALTIME, &time)
		
		return time
	}
	
#if os(macOS)
	public static func settime(
		_ time: timespec
	) -> Void {
		var time = time
		clock_settime(CLOCK_REALTIME, &time)
	}
#endif	
	
}
