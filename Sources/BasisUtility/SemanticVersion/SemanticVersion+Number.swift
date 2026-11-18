import Basis


extension SemanticVersion {
	
	/// 桁数に上限のない、先頭ゼロを持たない非負整数。
	public struct Number : Sendable, Hashable, Comparable,
												 ExpressibleByIntegerLiteral, CustomStringConvertible
	{
		public let description: String
		
		public init(_ text: String) throws {
			guard
				SemanticVersion.isNumeric(text),
				text == "0" || !text.hasPrefix("0")
			else { throw GeneralError.invalidFormat("SemVer数値: \(text)") }
			
			description = text
		}
		
		public init(
			_ value: UInt,
		) {
			description = String(value)
		}
		
		public init(
			integerLiteral value: UInt64,
		) {
			description = String(value)
		}
		
		public static func < (
			lhs: Self,
			rhs: Self,
		) -> Bool {
			if lhs.description.count != rhs.description.count {
				return lhs.description.count < rhs.description.count
			}

			return lhs.description < rhs.description
		}
		
		/// 10進数の桁を直接繰り上げ、固定幅整数の上限を避ける。
		public var incremented: Self {
			var bytes: [UInt8] = Array(description.utf8)
			for index in bytes.indices.reversed() {
				if bytes[index] < 57 {
					bytes[index] += 1
					return .init(
						validated: String(decoding: bytes, as: UTF8.self)
					)
				}
				bytes[index] = 48
			}
			return .init(
				validated: "1" + String(decoding: bytes, as: UTF8.self)
			)
		}
		
		private init(
			validated: String,
		) {
			description = validated
		}
	}
	
}
