import Basis


public extension Logger {
	
	@discardableResult
	func connect<Stream : TextOutputStream & Sendable> (
		level outputLevel: LogLevel = .all,
		to stream: Stream = Backbone.outputStream,
	) -> CancellableToken {
		return onLog.subscribe { level, message in
			guard
				level <= outputLevel
			else { return }

			var stream = stream
			print("[\(level)]", message, to: &stream)
		}
	}
	
}
