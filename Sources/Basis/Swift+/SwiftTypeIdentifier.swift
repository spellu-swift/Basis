
///
/// Swift型名
///
public struct SwiftTypeIdentifier : Sendable {

	/// 指定した値の実行時の型から作成する
	public static func of(
		_ value: Any?,
	) -> SwiftTypeIdentifier {
		if
			let value
		{
			return .init(type(of: value))
		}
		else {
			return .init("Swift.Nil") // Special case
		}
	}
	
	/// コンパイル時の型から作成する
	public init<T>(
		_ type: T.Type,
	) {
		self.init(String(reflecting: type))
	}
	
	private init(
		_ type: any Any.Type,
	) {
		self.init(String(reflecting: type))
	}
	
	private init(
		_ fullQuoalifiedName: String,
	) {
		let match = fullQuoalifiedName.wholeMatch(of: #/(.+?)(?:\<(.+)\>)?/#)
		
		assert(match != nil)
		
		self.components = match!.1.split(separator: ".")
		
		if
			let match_2 = match!.2
		{
			self.generics = match_2.split(separator: ", ").map{ SwiftTypeIdentifier($0.asString) }
		}
		else {
			self.generics = []
		}
	}

	public let components: [Substring]

	public let generics: [SwiftTypeIdentifier]
	
	@inlinable
	public var name: String {
		components.last?.asString ?? ""
	}

	@inlinable
	public var nameInModule: String {
		components.dropFirst().joined(separator: ".")
	}
	
	@inlinable
	public var fullQualifiedName: String {
		components.joined(separator: ".")
	}

}


extension SwiftTypeIdentifier : Equatable {}


extension SwiftTypeIdentifier : CustomStringConvertible {
	
	public var description: String {
		if generics.isEmpty {
			nameInModule
		}
		else {
			"\(nameInModule)<\(generics.map(\.nameInModule).joined(separator: ", "))>"
		}
	}
	
}

