import Basis


/// Semantic Versioning 2.0.0に従うバージョン。
/// https://semver.org/spec/v2.0.0.html
/// 比較・等価判定・ハッシュは優先順位を表し、buildを無視する。
public struct SemanticVersion : Sendable {
	
	public let major: Number
	public let minor: Number
	public let patch: Number
	public let prerelease: [String]
	public let build: String?
	
	public init(
		major: Number,
		minor: Number,
		patch: Number,
		prerelease: [String] = [],
		build: String? = nil
	) throws {
		try Self.validate(prerelease, numericLeadingZeros: false)
		if let build {
			try Self.validate(
				build.split(separator: ".", omittingEmptySubsequences: false)
					.map(String.init),
				numericLeadingZeros: true
			)
		}
		self.init(
			validatedMajor: major,
			minor: minor,
			patch: patch,
			prerelease: prerelease,
			build: build
		)
	}
	
	private init(
		validatedMajor major: Number,
		minor: Number,
		patch: Number,
		prerelease: [String] = [],
		build: String? = nil
	) {
		self.major = major
		self.minor = minor
		self.patch = patch
		self.prerelease = prerelease
		self.build = build
	}
	
	public static func parse(
		_ text: String,
	) throws -> Self {
		let metadata: [Substring]
		= text.split(
			separator: "+",
			omittingEmptySubsequences: false,
		)
		
		guard metadata.count <= 2 else {
			throw GeneralError.invalidFormat("SemVer: \(text)")
		}
		
		let release: [Substring]
		= metadata[0].split(
			separator: "-",
			maxSplits: 1,
			omittingEmptySubsequences: false,
		)
		
		let core: [Substring]
		= release[0].split(
			separator: ".",
			omittingEmptySubsequences: false,
		)
		
		guard
			core.count == 3
				else {
			throw GeneralError.invalidFormat("SemVerにはmajor.minor.patchが必要です")
		}
		
		let prerelease: [String]
		= if release.count == 2 {
			release[1].split(separator: ".", omittingEmptySubsequences: false)
				.map(String.init)
		} else { [] }
		
		return try .init(
			major: Number(String(core[0])),
			minor: Number(String(core[1])),
			patch: Number(String(core[2])),
			prerelease: prerelease,
			build: metadata.count == 2 ? String(metadata[1]) : nil
		)
	}
	
	/// コアを増加し、プレリリースとビルドメタデータは取り除く。
	public var majorIncremented: Self {
		.init(validatedMajor: major.incremented, minor: 0, patch: 0)
	}
	
	public var minorIncremented: Self {
		.init(validatedMajor: major, minor: minor.incremented, patch: 0)
	}
	
	public var patchIncremented: Self {
		.init(validatedMajor: major, minor: minor, patch: patch.incremented)
	}
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.major == rhs.major && lhs.minor == rhs.minor
		&& lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
	}
	
	static func isNumeric(
		_ text: String,
	) -> Bool {
		text.isNotEmpty
		&& text.utf8.allSatisfy { (48...57).contains($0) }
	}

	static func validate(
		_ identifiers: [String],
		numericLeadingZeros: Bool,
	) throws {
		for identifier in identifiers {
			guard
				identifier.isNotEmpty,
				identifier.utf8.allSatisfy({
					(48...57).contains($0) || (65...90).contains($0)
					|| (97...122).contains($0) || $0 == 45
				}),
				numericLeadingZeros || !isNumeric(identifier)
					|| identifier == "0" || !identifier.hasPrefix("0")
			else {
				throw GeneralError.invalidFormat("SemVer識別子: \(identifier)")
			}
		}
	}

}


extension SemanticVersion : Codable {
	
	public func encode(
		to encoder: any Encoder,
	) throws {
		var container = encoder.singleValueContainer()
		try container.encode(description)
	}

	public init(
		from decoder: any Decoder,
	) throws {
		let container = try decoder.singleValueContainer()
		let text: String = try container.decode(String.self)
		do { self = try Self.parse(text) } catch {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "SemVerとして不正です: \(text)"
			)
		}
	}

}


extension SemanticVersion : Hashable {
	
	public func hash(
		into hasher: inout Hasher,
	) {
		hasher.combine(major)
		hasher.combine(minor)
		hasher.combine(patch)
		hasher.combine(prerelease)
	}
	
}


extension SemanticVersion : Comparable {
	
	public static func < (
		lhs: Self,
		rhs: Self,
	) -> Bool {
		if lhs.major != rhs.major { return lhs.major < rhs.major }
		if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
		if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

		if lhs.prerelease.isEmpty { return false }
		if rhs.prerelease.isEmpty { return true }

		for (left, right)
			in zip(lhs.prerelease, rhs.prerelease)
			where left != right
		{
			let leftNumeric: Bool = isNumeric(left)
			let rightNumeric: Bool = isNumeric(right)

			if leftNumeric != rightNumeric {
				return leftNumeric
			}

			if
				leftNumeric,
				left.count != right.count
			{
				return left.count < right.count
			}

			return left < right
		}

		return lhs.prerelease.count < rhs.prerelease.count
	}
	
}


extension SemanticVersion : CustomStringConvertible {
	
	public var description: String {
		var text: String
		= "\(major).\(minor).\(patch)"
		
		if prerelease.isNotEmpty {
			text += "-" + prerelease.joined(separator: ".")
		}

		if let build {
			text += "+" + build
		}

		return text
	}

}
