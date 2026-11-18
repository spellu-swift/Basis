import Libc


extension POSIX {

	public static func user(
		name: String?
	) -> passwd? {
		if let name = name {
			guard let result = getpwnam(name)
			else { return nil }
			
			return result.pointee
		}
		else {
			guard let result = getpwuid(uid)
			else { return nil }
			
			return result.pointee
		}
	}
		
	static var uid: uid_t {
		ugid.0
	}
	
	static var gid: gid_t {
		ugid.1
	}
	
	static var ugid: (uid_t, gid_t) {
#if canImport(Darwin)
		var uid: uid_t = .init()
		var gid: gid_t = .init()
		
		if pthread_getugid_np(&uid, &gid) == 0 {
			return (uid, gid)
		}
#endif
		
		let euid = geteuid()
		if euid > 0 {
			return (euid, getegid())
		}
		else {
			return (getuid(), getgid())
		}
	}
		
}
