import Libc


extension POSIX {
	
	@inlinable
	public static func format(
		_ format: String,
		_ arguments: CVarArg...,
	) -> String {
		POSIX.format(format, arguments)
	}
	
	public static func format(
		_ format: String,
		_ arguments: [CVarArg],
	) -> String {
		let capacity: Int = withVaList(arguments) { valist in
			Int(vsnprintf(nil, 0, format, valist))
		} + 1
		
		let buffer: UnsafeMutablePointer<UInt8> = .allocate(
			capacity: capacity,
		)
		
		defer {
			buffer.deallocate()
		}
		
		let count: Int = withVaList(arguments) { valist in
			Int(vsnprintf(buffer, capacity, format, valist))
		}
		
		return String(
			decoding: UnsafeBufferPointer<UInt8>(start: buffer, count: count),
			as: UTF8.self,
		)
	}

	/// 文字列を書式に従い解釈し、UTC時刻に変換する。
	/// format: "%Y-%m-%dT%H:%M:%SZ" などと指定できる。
	public static func strptime(
		_ string: String,
		format: String,
	) -> ClockTime? {
		var date: tm = .init()

		let valid: Bool
		= string.withCString {
			guard
				let end = Libc.strptime(
					$0,
					format,
					&date
				)
			else { return false }

			return end.pointee == 0
		}

		guard valid else { return nil }

		return .clock(timegm(&date))
	}

	/// 時刻を書式に従い、UTCの文字列に変換する。``strptime(_:format:)``の逆変換。
	/// format: "%Y-%m-%dT%H:%M:%SZ" などと指定できる。秒未満は切り捨てる。
	public static func strftime(
		_ time: ClockTime,
		format: String,
	) -> String? {
		var seconds: time_t = time.seconds
		var date: tm = .init()

		guard gmtime_r(&seconds, &date) != nil
		else { return nil }

		guard format.isNotEmpty
		else { return "" }

		// 結果が空になる書式と、バッファ不足を区別できないため、上限まで広げて試す。
		var capacity: Int = 64

		while capacity <= 64 * 1024 {
			let result: String?
			= withUnsafeTemporaryAllocation(
				of: CChar.self,
				capacity: capacity,
			) { buffer in
				let count: Int
				= Libc.strftime(
					buffer.baseAddress!,
					capacity,
					format,
					&date,
				)

				guard count > 0
				else { return nil }

				return String(
					decoding: UnsafeRawBufferPointer(
						start: buffer.baseAddress!,
						count: count,
					),
					as: UTF8.self,
				)
			}

			if let result {
				return result
			}

			capacity *= 4
		}

		return nil
	}
	
}
