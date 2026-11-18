

extension URI {
	
	/// 構文に基づく正規化。スキーム固有の既定ポートや空パスは変更しない。
	/// 相対参照のドットセグメントは、基底URIに対する意味を保つため残す。
	public func normalized() -> URI {
		var result: URI = self
		
		result.scheme = scheme?.lowercased()
		
		if var authority {
			authority.userInfo = authority.userInfo.map(normalizePercentEncoding)
			authority.host = normalizePercentEncoding(
				normalizePercentEncoding(authority.host).lowercased()
			)
			result.authority = authority
		}
		
		result.path = normalizePercentEncoding(path)
		
		if isAbsolute {
			result.path = Self.removeDotSegments(result.path)
		}
		
		result.query = query.map(normalizePercentEncoding)
		result.fragment = fragment.map(normalizePercentEncoding)
		result.protectPathSyntax()
		
		return result
	}
	
	public mutating func normalize() {
		self = normalized()
	}

	/// normalized()と同じ範囲で比較する。構造的な==の結果には影響しない。
	public func isEquivalent(
		to other: URI,
	) -> Bool {
		normalized() == other.normalized()
	}
	
}


private func normalizePercentEncoding(
	_ string: String,
) -> String {
	let PERCENT: UInt8 = 0x25

	let bytes: [UInt8]
	= Array(string.utf8)

	let hex: [UInt8]
	= Array("0123456789ABCDEF".utf8)

	var result: [UInt8] = []

	var index: Int = 0

	while index < bytes.count {
		if
			bytes[index] == PERCENT,
			index + 2 < bytes.count,
			let high = URI.hexValue(bytes[index + 1]),
			let low = URI.hexValue(bytes[index + 2])
		{
			let byte = high * 16 + low
			if URI.isUnreserved(byte) {
				result.append(byte)
			}
			else {
				result.append(contentsOf: [PERCENT, hex[Int(high)], hex[Int(low)]])
			}
			index += 3
		}
		else {
			result.append(bytes[index])
			index += 1
		}
	}

	return result.asString
}
