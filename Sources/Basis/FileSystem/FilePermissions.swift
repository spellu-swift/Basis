import Libc


/// ファイルの権限。`mode_t`の下位12ビットに当たる。
///
/// 8進数のリテラル、対象ごとの指定、`ls -l`と同じ表記の文字列で作れる。
///
/// ```swift
/// let a: FilePermissions = 0o644
/// let b = FilePermissions(owner: .readWrite, group: .read, other: .read)
/// let c = FilePermissions("rw-r--r--")
/// ```
public struct FilePermissions : OptionSet, Sendable, Hashable {

	public let rawValue: UInt16

	@inlinable
	public init(
		rawValue: UInt16,
	) {
		self.rawValue = rawValue & 0o7777
	}

	public static let ownerRead    = FilePermissions(rawValue: 0o400)
	public static let ownerWrite   = FilePermissions(rawValue: 0o200)
	public static let ownerExecute = FilePermissions(rawValue: 0o100)
	public static let groupRead    = FilePermissions(rawValue: 0o040)
	public static let groupWrite   = FilePermissions(rawValue: 0o020)
	public static let groupExecute = FilePermissions(rawValue: 0o010)
	public static let otherRead    = FilePermissions(rawValue: 0o004)
	public static let otherWrite   = FilePermissions(rawValue: 0o002)
	public static let otherExecute = FilePermissions(rawValue: 0o001)
	public static let setUserID    = FilePermissions(rawValue: 0o4000)
	public static let setGroupID   = FilePermissions(rawValue: 0o2000)
	public static let sticky       = FilePermissions(rawValue: 0o1000)

}


// MARK: - Access


extension FilePermissions {

	/// 1つの対象（所有者・グループ・その他）に対する、読み・書き・実行の組み合わせ。
	public struct Access : OptionSet, Sendable, Hashable {

		public let rawValue: UInt16

		@inlinable
		public init(
			rawValue: UInt16,
		) {
			self.rawValue = rawValue & 0o7
		}

		public static let read    = Access(rawValue: 0o4)
		public static let write   = Access(rawValue: 0o2)
		public static let execute = Access(rawValue: 0o1)

		public static let readWrite: Access   = [.read, .write]
		public static let readExecute: Access = [.read, .execute]
		public static let all: Access         = [.read, .write, .execute]

	}

	@inlinable
	public init(
		owner: Access = [],
		group: Access = [],
		other: Access = [],
	) {
		self.init(
			rawValue: owner.rawValue << 6 | group.rawValue << 3 | other.rawValue,
		)
	}

	/// 指定した権限をすべて持っているか。
	///
	/// ```swift
	/// permissions.containsAll(owner: .execute)                  // 所有者が実行できる
	/// permissions.containsAll(owner: .readWrite, group: .read)  // 両方を満たす
	/// ```
	@inlinable
	public func containsAll(
		owner: Access = [],
		group: Access = [],
		other: Access = [],
	) -> Bool {
		contains(
			FilePermissions(owner: owner, group: group, other: other),
		)
	}

	/// 指定した権限のどれか1つでも持っているか。
	///
	/// ```swift
	/// // 誰か1人でも実行できる
	/// permissions.containsAny(owner: .execute, group: .execute, other: .execute)
	/// ```
	@inlinable
	public func containsAny(
		owner: Access = [],
		group: Access = [],
		other: Access = [],
	) -> Bool {
		!isDisjoint(
			with: FilePermissions(owner: owner, group: group, other: other),
		)
	}

	@inlinable
	public var owner: Access {
		Access(rawValue: rawValue >> 6)
	}

	@inlinable
	public var group: Access {
		Access(rawValue: rawValue >> 3)
	}

	@inlinable
	public var other: Access {
		Access(rawValue: rawValue)
	}

}


// MARK: - mode_t


extension FilePermissions {

	@inlinable
	package init(
		mode: mode_t,
	) {
		self.init(rawValue: UInt16(truncatingIfNeeded: mode))
	}

	@inlinable
	package var mode: mode_t {
		mode_t(rawValue)
	}

}


// MARK: - Literal


extension FilePermissions : ExpressibleByIntegerLiteral {

	@inlinable
	public init(
		integerLiteral value: UInt16,
	) {
		self.init(rawValue: value)
	}

}


// MARK: - String


extension FilePermissions : LosslessStringConvertible {

	/// `ls -l`の権限の部分と同じ9文字の表記（例: `rwxr-xr-x`）から作る。
	///
	/// 実行の位置には、特殊な権限を表す`s` `S`（所有者・グループ）、`t` `T`（その他）も書ける。
	public init?(
		_ description: String,
	) {
		let characters: [Character] = Array(description)

		guard characters.count == 9 else { return nil }

		var result: FilePermissions = []

		for (index, (bit, special)) in Self.layout.enumerated() {
			let base: Int = index * 3

			guard
				let read = Self.flag(characters[base], "r"),
				let write = Self.flag(characters[base + 1], "w")
			else { return nil }

			if read { result.insert(bit.read) }
			if write { result.insert(bit.write) }

			switch characters[base + 2] {
				case "-":
					break
				case "x":
					result.insert(bit.execute)
				case special.lowercase:
					result.insert(bit.execute)
					result.insert(special.bit)
				case special.uppercase:
					result.insert(special.bit)
				default:
					return nil
			}
		}

		self = result
	}

	public var description: String {
		var result: String = ""

		for (bit, special) in Self.layout {
			result.append(contains(bit.read) ? "r" : "-")
			result.append(contains(bit.write) ? "w" : "-")

			switch (contains(bit.execute), contains(special.bit)) {
				case (false, false):
					result.append("-")
				case (true, false):
					result.append("x")
				case (true, true):
					result.append(special.lowercase)
				case (false, true):
					result.append(special.uppercase)
			}
		}

		return result
	}

	private typealias Bits = (
		read: FilePermissions,
		write: FilePermissions,
		execute: FilePermissions,
	)

	private typealias Special = (
		bit: FilePermissions,
		lowercase: Character,
		uppercase: Character,
	)

	private static let layout: [(Bits, Special)] = [
		(
			(.ownerRead, .ownerWrite, .ownerExecute),
			(.setUserID, "s", "S"),
		),
		(
			(.groupRead, .groupWrite, .groupExecute),
			(.setGroupID, "s", "S"),
		),
		(
			(.otherRead, .otherWrite, .otherExecute),
			(.sticky, "t", "T"),
		),
	]

	private static func flag(
		_ character: Character,
		_ expected: Character,
	) -> Bool? {
		switch character {
			case "-": false
			case expected: true
			default: nil
		}
	}

}
