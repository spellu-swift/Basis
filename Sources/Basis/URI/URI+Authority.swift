

extension URI.Authority {

	/// IPv6・IPvFutureの角括弧をhostに保持する。
	public init?(
		_ string: String,
	) {
		guard
			let match = string.wholeMatch(of: #/(?:(?<userInfo>[^@]*)@)?(?<host>\[[^\]]*\]|[^:]*)(?::(?<port>[0-9]*))?/#)
		else { return nil }

		let userInfo: String?
		= match.userInfo.map(String.init)

		let host: String
		= String(match.host)

		guard
			userInfo.map(
				{ URI.isValid($0, component: .userInfo) }
			) ?? true
		else { return nil }

		if host.hasPrefix("[") {
			let address: String
			= String(host.dropFirst().dropLast())

			guard
				Self.isIPv6(address)
					|| address.wholeMatch(of: #/[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!$&'()*+,;=:-]+/#) != nil
			else { return nil }
		}
		else {
			guard
				URI.isValid(host, component: .host)
			else { return nil }
		}

		self.init(
			userInfo: userInfo,
			host: host,
			port: match.port.map(String.init),
		)
	}

	public var asString: String {
		(userInfo.map { "\($0)@" } ?? "") + host + (port.map { ":\($0)" } ?? "")
	}

	public var portNumber: Int? {
		guard let port, !port.isEmpty, port.utf8.allSatisfy({ (48...57).contains($0) })
		else { return nil }
		return Int(port)
	}

	private static func isIPv6(
		_ string: String,
	) -> Bool {
		// IPv4埋め込み部分は末尾の2個の16ビットグループに相当する。
		var address: String = string

		if address.contains(".") {
			guard
				let colon = address.lastIndex(of: ":")
			else { return false }

			let ipv4 = address[address.index(after: colon)...].split(separator: ".", omittingEmptySubsequences: false)

			guard
				ipv4.count == 4,
				ipv4.allSatisfy({ part in
					part.isNotEmpty
					&& (part.count == 1 || part.first != "0")
					&& part.utf8.allSatisfy { (48...57).contains($0) }
					&& UInt8(part) != nil
				})
			else { return false }

			address = String(address[...colon]) + "0:0"
		}

		let halves = address.split(separator: "::", omittingEmptySubsequences: false)

		guard
			halves.count <= 2
		else { return false }

		var count: Int = 0

		for half in halves where !half.isEmpty {
			let groups = half.split(separator: ":", omittingEmptySubsequences: false)

			guard
				groups.allSatisfy({ $0.wholeMatch(of: #/[0-9A-Fa-f]{1,4}/#) != nil })
			else { return false }

			count += groups.count
		}

		return halves.count == 2 ? count < 8 : count == 8
	}

}
