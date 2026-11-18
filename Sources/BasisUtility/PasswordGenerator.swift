import Basis


/// パスワード生成器
/// TODO: 日本語を使えるようにする‼️
public class PasswordGenerator {
	
	
	public struct Options : OptionSet, Sendable {
		public init(
			rawValue: Int
		) {
			self.rawValue = rawValue
		}
		
		
		public let rawValue: Int

		
		public static let symbol: Self = .init(rawValue: 1 << 1)
	}
	

	/// シンプルなパスワード生成
	public static func generate(
		length: Int,
		options: Options = []
	) -> String {
		let 英字 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let 数字 = "0123456789"
		let 記号 = "!@#$%^&*()_-+=<>?"
		
		let 使用可能な文字: String
		if options.contains(.symbol) {
			使用可能な文字 = 英字 + 数字 + 記号
		} else {
			使用可能な文字 = 英字 + 数字
		}
		
		return (
			0..<length
		)
		.map { _ in
			使用可能な文字.randomElement()!
		}
		.asString
	}
	
	
}
