

@attached(extension, names: named(`default`), conformances: Default)
public macro Default()
= #externalMacro(module: "BasisMacros", type: "DefaultMacro")


public protocol Default {
	static var `default`: Self { get }
}


extension Bool : Default {
	public static let `default`: Self = false
}

extension Int8 : Default {
	public static let `default`: Self = 0
}

extension Int16 : Default {
	public static let `default`: Self = 0
}

extension Int32 : Default {
	public static let `default`: Self = 0
}

extension Int64 : Default {
	public static let `default`: Self = 0
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Int128 : Default {
	public static let `default`: Self = 0
}

extension Int : Default {
	public static let `default`: Self = 0
}

extension UInt8 : Default {
	public static let `default`: Self = 0
}

extension UInt16 : Default {
	public static let `default`: Self = 0
}

extension UInt32 : Default {
	public static let `default`: Self = 0
}

extension UInt64 : Default {
	public static let `default`: Self = 0
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension UInt128 : Default {
	public static let `default`: Self = 0
}

extension UInt : Default {
	public static let `default`: Self = 0
}

extension Float32 : Default {
	public static let `default`: Self = 0
}

extension Float64 : Default {
	public static let `default`: Self = 0
}

//extension Float80 : Default {
//	public static let `default`: Self = 0
//}

extension Binary : Default {
	public static let `default`: Self = .empty
}

extension String : Default {
	public static let `default`: Self = .empty
}

extension ZonedDateTime : Default {
	public static let `default`: Self = .EPOCH
}

extension LocalDateTime : Default {
	public static let `default`: Self = .EPOCH
}

extension LocalDate : Default {
	public static let `default`: Self = .EPOCH
}

extension LocalTime : Default {
	public static let `default`: Self = .MIN
}

extension Array : Default {
	@inlinable
	public static var `default`: Self { [] }
}

extension Set : Default {
	@inlinable
	public static var `default`: Self { [] }
}

extension Dictionary : Default {
	@inlinable
	public static var `default`: Self { [:] }
}

extension OrderedDictionary : Default {
	@inlinable
	public static var `default`: Self { [:] }
}
