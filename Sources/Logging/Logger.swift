import Basis


///
/// ログを記録するもの
///
public struct Logger : Logging, Sendable {
	
	public init() {
		self.outputLevel = .off
	}

	public var outputLevel: LogLevel

	/// ログイベント
	let onLog: Multicaster<(
		level: LogLevel,
		message: @Sendable () -> String,
	)>
	= .init()

	/// ログ出力
	public func log(
		_ level: LogLevel,
		_ message: String,
	) {
		if level <= outputLevel {
			onLog.send((level: level, message: {message}))
		}
	}
	
	/// ログ出力
	public func log(
		_ level: LogLevel,
		_ message: @Sendable @escaping () -> String,
	) {
		if level <= outputLevel {
			onLog.send((level: level, message: message))
		}
	}
	
}


public struct Log : Sendable {

	public let occured: ClockTime
	public let level: LogLevel
	public let arguments: [any Sendable]

}


//public protocol LogFomatter {
//	
//	var prefix: String { get }
//	var message: String { get }
//	
//}
