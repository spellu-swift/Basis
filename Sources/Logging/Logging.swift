import Basis


///
/// ロギングプロトコル
///
public protocol Logging : Sendable {
	
	func log(
		_ level: LogLevel,
		_ message: @Sendable @escaping () -> String,
	)
	
}


public extension Logging {
	
	func critical(
		_ message: String,
	) {
		log(.critical, {message})
	}
	
	func error(
		_ message: String,
	) {
		log(.error, {message})
	}
	
	func warning(
		_ message: String,
	) {
		log(.warning, {message})
	}
	
	func info(
		_ message: String,
	) {
		log(.info, {message})
	}
	
	func debug(
		_ message: String,
	) {
		log(.debug, {message})
	}
	
	func trace(
		_ message: String,
	) {
		log(.trace, {message})
	}
	
}


public extension Logging {

	func critical(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.critical, message)
	}
	
	func error(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.error, message)
	}
	
	func warning(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.warning, message)
	}
	
	func info(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.info, message)
	}
	
	func debug(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.debug, message)
	}
	
	func trace(
		_ message: @Sendable @escaping () -> String,
	) {
		log(.trace, message)
	}
	
}


//public extension Logging {
//
//	func log(
//		_ level: LogLevel,
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			level,
//			{ components.joined(separator: separator) },
//		)
//	}
//
//	func critical(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.critical,
//			{ components.joined(separator: separator) },
//		)
//	}
//
//	func error(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.error,
//			{ components.joined(separator: separator) },
//		)
//	}
//	
//	func warning(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.warning,
//			{ components.joined(separator: separator) },
//		)
//	}
//	
//	func info(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.info,
//			{ components.joined(separator: separator) },
//		)
//	}
//	
//	func debug(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.debug,
//			{ components.joined(separator: separator) },
//		)
//	}
//	
//	func trace(
//		_ components: [Any?],
//		separator: String = " ",
//	) {
//		log(
//			.trace,
//			{ components.joined(separator: separator) },
//		)
//	}
//	
//}


extension [Any?] {
	
	public var asString: [String] {
		map{ $0.map { String(describing: $0) } else: { "nil" } }
	}
	
	public func joined(
		separator: String,
	) -> String{
		asString.joined(separator: separator)
	}
	
}


