

///
/// タイムゾーン
///
@Orderable
public struct TimeZone : Sendable {
	
	public let name: String
		
	/// 基準オフセット。日時の変換にはoffset(at:)を使用する。
	public let offset: ZoneOffset
		
}


extension TimeZone {
	
	public static let utc: TimeZone
	= .init(name: "UTC", offset: .ofTotalSeconds(0))

}


extension TimeZone : Hashable {}


extension TimeZone : Codable {}


extension TimeZone : CustomStringConvertible {
	
	public var description: String {
		"\(offset.description)[\(name)]"
	}
		
}


//public static final Map<String, String> SHORT_IDS = Map.ofEntries(
//	entry("ACT", "Australia/Darwin"),
//	entry("AET", "Australia/Sydney"),
//	entry("AGT", "America/Argentina/Buenos_Aires"),
//	entry("ART", "Africa/Cairo"),
//	entry("AST", "America/Anchorage"),
//	entry("BET", "America/Sao_Paulo"),
//	entry("BST", "Asia/Dhaka"),
//	entry("CAT", "Africa/Harare"),
//	entry("CNT", "America/St_Johns"),
//	entry("CST", "America/Chicago"),
//	entry("CTT", "Asia/Shanghai"),
//	entry("EAT", "Africa/Addis_Ababa"),
//	entry("ECT", "Europe/Paris"),
//	entry("IET", "America/Indiana/Indianapolis"),
//	entry("IST", "Asia/Kolkata"),
//	entry("JST", "Asia/Tokyo"),
//	entry("MIT", "Pacific/Apia"),
//	entry("NET", "Asia/Yerevan"),
//	entry("NST", "Pacific/Auckland"),
//	entry("PLT", "Asia/Karachi"),
//	entry("PNT", "America/Phoenix"),
//	entry("PRT", "America/Puerto_Rico"),
//	entry("PST", "America/Los_Angeles"),
//	entry("SST", "Pacific/Guadalcanal"),
//	entry("VST", "Asia/Ho_Chi_Minh"),
//	entry("EST", "-05:00"),
//	entry("MST", "-07:00"),
//	entry("HST", "-10:00")
//	);

