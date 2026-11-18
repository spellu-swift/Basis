#if canImport(Darwin)
import Libc


extension Subprocess {
	
	func readOutputs(
		timeout: Double?,
		buffer: Buffer,
		onEvent: (InternalEvent) -> Void,
	) throws {
		let kq = try KQueue()
		
		try kq.registerEvent(
			descripter: .read(outFd),
			action: .add
		)
		try kq.registerEvent(
			descripter: .read(errFd),
			action: .add
		)
		
		var outputAvailable: Bool = true
		var errorAvailable: Bool = true
		
		while outputAvailable || errorAvailable {
			let (descripter, totalBytes): (KQueue.Descripter, Int) =
			try kq.waitEvent(
				timeout: timeout,
			)
			
			switch descripter {
				case .read(outFd):
					if
						let bytes = try read(
							fd: outFd,
							buffer: buffer,
							totalBytes: totalBytes
						)
					{
						onEvent(.output(bytes))
					}
					else {
						outputAvailable = false
					}
					
				case .read(errFd):
					if
						let bytes = try read(
							fd: errFd,
							buffer: buffer,
							totalBytes: totalBytes
						)
					{
						onEvent(.error(bytes))
					}
					else {
						errorAvailable = false
					}
					
				default:
					#print(
						"waitEvent",
						"Unknown descripter",
						descripter
					)
					break
			}
		}
	}
	
}
#endif
