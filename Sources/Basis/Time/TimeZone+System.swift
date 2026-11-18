import Libc


///
/// システムのタイムゾーンデータ（TZif形式）を使うタイムゾーンの機能
///
extension TimeZone {

	/// システムのタイムゾーン
	///
	/// 環境変数TZを優先し、なければ /etc/localtime のリンク先から決める。
	/// TZがPOSIXの書式（例: `JST-9`）なら、その規則を使う。
	public static var system: TimeZone {
		if
			let value = POSIX.environment["TZ"],
			value.isNotEmpty
		{
			// 先頭の「:」は、ファイル名の指定であることを表す。
			let name: String
			= value.hasPrefix(":") ? String(value.dropFirst()) : value

			if let zone = try? named(name) {
				return zone
			}

			if let rules = TimeZoneRegistry.shared.rules(posix: name) {
				return from(name: name, rules: rules)
			}

			return .utc
		}

		if
			let name = localtimeName,
			let zone = try? named(name)
		{
			return zone
		}

		return .utc
	}

	/// 名前（例: `Asia/Tokyo`）で指定したタイムゾーン
	public static func named(
		_ name: String,
	) throws -> Self {
		guard
			let rules = TimeZoneRegistry.shared.rules(named: name)
		else { throw GeneralError.invalidTimeZone(name) }

		return from(name: name, rules: rules)
	}

	/// 基準オフセットは、2001-01-01T00:00:00Z時点のオフセットとする。
	static func from(
		name: String,
		rules: TimeZoneRules,
	) -> Self {
		TimeZone(
			name: name,
			offset: .ofTotalSeconds(
				rules.offset(at: Int64(ClockTime.between1970_2001)),
			),
		)
	}

	/// /etc/localtime のリンク先から求めたゾーン名
	static var localtimeName: String? {
		guard
			let target = try? POSIX.readlink(at: "/etc/localtime"),
			let range = target.firstRange(of: "zoneinfo/")
		else { return nil }

		return String(target[range.upperBound...])
	}


	/// 指定した瞬間に有効なUTCオフセット。
	public func offset(
		at clock: ClockTime,
	) -> ZoneOffset {
		guard
			let rules = TimeZoneRegistry.shared.rules(named: name)
				?? TimeZoneRegistry.shared.rules(posix: name)
		else { return offset }

		return .ofTotalSeconds(rules.offset(at: Int64(clock.seconds)))
	}

	/// 重複は先の時刻、欠落は移行幅だけ進める。
	@usableFromInline
	func epochSecond(
		for local: LocalDateTime,
	) -> Int {
		let localSecond = local.date.epochDay * SECONDS_PER_DAY + local.time.secondOfDay
		let reference = localSecond - offset.totalSeconds

		// 前後の規則から候補を作る。暦の再計算を避け、グレゴリオ暦を保つ。
		let offsets = Set([-2 * SECONDS_PER_DAY, 0, 2 * SECONDS_PER_DAY].map {
			offset(at: .clock(reference + $0)).totalSeconds
		})
		let candidates = offsets.map { localSecond - $0 }
		let valid = candidates.filter {
			$0 + offset(at: .clock($0)).totalSeconds == localSecond
		}

		// 重複時は時間軸上で先に現れる候補を選ぶ。
		if let first = valid.min() { return first }

		// 欠落時は旧オフセットの候補を採用し、移行幅だけ先へ進める。
		let forward = candidates.filter {
			$0 + offset(at: .clock($0)).totalSeconds > localSecond
		}
		guard let first = forward.min()
		else { preconditionFailure("Local date-time cannot be resolved in zone \(name)") }

		return first
	}

}


///
/// 名前ごとのタイムゾーンの規則を読み込み、保持する。
///
final class TimeZoneRegistry : Sendable {

	static let shared: TimeZoneRegistry
	= .init()

	/// TZif形式のファイルを探すディレクトリ
	static var directories: [String] {
		var directories: [String] = []

		if let value = POSIX.environment["TZDIR"], value.isNotEmpty {
			directories.append(value)
		}

		directories.append("/var/db/timezone/zoneinfo")
		directories.append("/usr/share/zoneinfo")

		return directories
	}

	/// 読み込んだ規則。見つからなかった名前はnilを保持する。
	let cache: Barrier<[String : TimeZoneRules?]>
	= .init([:])

	/// TZif形式のファイルから規則を得る。
	func rules(
		named name: String,
	) -> TimeZoneRules? {
		if name == "UTC" || name == "GMT" {
			return .init(
				transitions: [],
				offsets: [],
				initialOffset: 0,
				footer: nil,
			)
		}

		let key: String = "file:" + name

		if let cached = cached(key) {
			return cached
		}

		let rules: TimeZoneRules? = Self.load(name)
		store(key, rules)
		return rules
	}

	/// POSIXのTZ文字列から規則を得る。
	func rules(
		posix string: String,
	) -> TimeZoneRules? {
		let key: String = "posix:" + string

		if let cached = cached(key) {
			return cached
		}

		let rules: TimeZoneRules?
		= PosixRule(string: string).map {
			.init(
				transitions: [],
				offsets: [],
				initialOffset: $0.standardOffset,
				footer: $0,
			)
		}

		store(key, rules)
		return rules
	}

	private func cached(
		_ key: String,
	) -> TimeZoneRules?? {
		cache.read {
			.ok($0[key])
		}
	}

	private func store(
		_ key: String,
		_ rules: TimeZoneRules?,
	) {
		cache.write {
			$0[key] = .some(rules)

			return .through
		}
	}

	/// ゾーン名に対応するTZif形式のファイルを読み込む。
	private static func load(
		_ name: String,
	) -> TimeZoneRules? {
		// ディレクトリの外を指す名前は受け付けない。
		guard
			name.isNotEmpty,
			!name.hasPrefix("/"),
			!name
				.split(separator: "/")
				.contains(where: { $0 == ".." || $0 == "." })
		else { return nil }

		for directory in directories {
			let path: FilePath = FilePath(directory + "/" + name)

			guard
				let binary = try? path.file.load()
			else { continue }

			return TimeZoneRules(tzif: binary.asBytes)
		}

		return nil
	}

}
