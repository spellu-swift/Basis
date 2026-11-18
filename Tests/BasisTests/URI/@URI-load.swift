#if os(macOS) || canImport(Glibc)
@testable import Basis
import Libc


@Suite(.serialized)
struct URILoadTests {

	// MARK: http, https

	@Test func httpで本文を取得する() throws {
		let body: [UInt8] = (0..<3000).map { .init($0 % 256) }
		let server: TestHTTPServer = try .init(
			routes: ["/data": .init(status: 200, body: body)],
		)

		#expect(try server.uri("/data").load().asBytes == body)
	}

	@Test func スキームの大文字と小文字を区別しない() throws {
		let server: TestHTTPServer = try .init(
			routes: ["/": .init(status: 200, body: "ok".asBytes)],
		)
		var uri: URI = server.uri("/")

		uri.scheme = "HTTP"

		#expect(try uri.load().asString == "ok")
	}

	@Test func リダイレクトに従う() throws {
		let server: TestHTTPServer = try .init(
			routes: [
				"/old": .init(status: 302, headers: ["Location: /new"]),
				"/new": .init(status: 200, body: "moved".asBytes),
			],
			connections: 2,
		)

		#expect(try server.uri("/old").load().asString == "moved")
	}

	@Test(arguments: [400, 404, 500, 503])
	func 失敗の応答は送出する(
		_ status: Int,
	) throws {
		let server: TestHTTPServer = try .init(
			routes: ["/": .init(status: status, body: "error".asBytes)],
		)

		#expect(throws: GeneralError.self) {
			try server.uri("/").load()
		}
	}

	@Test func fileへのリダイレクトは送出する() throws {
		let server: TestHTTPServer = try .init(
			routes: [
				"/": .init(status: 302, headers: ["Location: file:///etc/hosts"]),
			],
		)

		#expect(throws: GeneralError.self) {
			try server.uri("/").load()
		}
	}

	@Test func 制限時間を過ぎたら送出する() throws {
		// 応答を返さず、curlが接続を閉じるまで待つ。
		let server: TestHTTPServer = try .init(
			routes: [:],
		)
		let clock: ContinuousClock = .init()
		let started: ContinuousClock.Instant = clock.now

		#expect(throws: GeneralError.self) {
			try server.uri("/").load(timeout: 0.5)
		}

		#expect(clock.now - started < .seconds(5))
	}

	@Test func 接続できなければ送出する() throws {
		// 待ち受けを閉じたポートには接続できない。
		let uri: URI = try {
			let server: TestHTTPServer = try .init(
				routes: [:],
				connections: 0,
			)

			return server.uri("/")
		}()

		#expect(throws: GeneralError.self) {
			try uri.load(timeout: 5)
		}
	}

	@Test func httpsで取得する() throws {
		let uri: URI = "https://example.com/"

		#expect(try uri.load(timeout: 30).isNotEmpty)
	}

	// MARK: file

	@Test func fileのファイルを読み込む() throws {
		let uri: URI = .file(fixtureDirectory[file: "hello"].path)

		#expect(try uri.load().asString == "Hello!\n")
	}

	@Test func 存在しないファイルは送出する() throws {
		let uri: URI = .file("/<missing>/file")

		#expect(throws: FileSystemError.self) {
			try uri.load()
		}
	}

	@Test func リモートホストのfileは送出する() throws {
		let uri: URI = "file://example.com/etc/hosts"

		#expect(throws: GeneralError.notSupported) {
			try uri.load()
		}
	}

	// MARK: その他

	@Test(arguments: [
		"ftp://example.com/",
		"mailto:user@example.com",
		"relative/path",
	])
	func 対応していないスキームは送出する(
		_ string: String,
	) throws {
		let uri: URI = try .parse(string)

		#expect(throws: GeneralError.notSupported) {
			try uri.load()
		}
	}

	@Test func curlの引数() throws {
		#expect(
			try URI.curlArguments("-o", timeout: nil) == [
				"curl",
				"--fail",
				"--silent",
				"--show-error",
				"--location",
				"--proto", "=http,https",
				"--proto-redir", "=http,https",
				"--url", "-o",
			]
		)
		#expect(
			try URI.curlArguments("http://a/", timeout: 1.5).suffix(4) == [
				"--max-time", "1.5",
				"--url", "http://a/",
			]
		)
	}

	@Test(arguments: [0, -1, Double.infinity, Double.nan])
	func 制限時間には正の有限値だけを受け付ける(
		_ timeout: Double,
	) {
		#expect(throws: GeneralError.self) {
			try URI.curlArguments("http://a/", timeout: timeout)
		}
	}

}


/// テスト用のHTTPサーバー。決めた数の接続に1件ずつ応答して終わる。
///
/// 登録のないパスには応答せず、クライアントが接続を閉じるまで待つ。
private final class TestHTTPServer: Sendable {

	struct Response: Sendable {

		init(
			status: Int,
			headers: [String] = [],
			body: [UInt8] = [],
		) {
			self.status = status
			self.headers = headers
			self.body = body
		}

		let status: Int
		let headers: [String]
		let body: [UInt8]

	}

	init(
		routes: [String : Response],
		connections: Int = 1,
	) throws {
		let fd: Int32 = Self.makeSocket()

		guard
			fd != -1
		else { throw POSIXError.system }

		var address: sockaddr_in = .init()
		#if canImport(Darwin)
		address.sin_len = .init(MemoryLayout<sockaddr_in>.size)
		#endif
		address.sin_family = .init(AF_INET)
		address.sin_addr.s_addr = inet_addr("127.0.0.1")

		var length: socklen_t = .init(MemoryLayout<sockaddr_in>.size)
		let result: Int32 = withUnsafeMutablePointer(to: &address) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				guard
					bind(fd, $0, length) == 0,
					listen(fd, 8) == 0
				else { return -1 }

				return getsockname(fd, $0, &length)
			}
		}

		guard
			result == 0
		else {
			close(fd)

			throw POSIXError.system
		}

		self.port = .init(bigEndian: address.sin_port)

		guard
			connections > 0
		else {
			close(fd)

			return
		}

		_ = Task.detached {
			defer { close(fd) }

			for _ in 0..<connections {
				let client: Int32 = accept(fd, nil, nil)

				guard
					client != -1
				else { return }

				Self.respond(client, routes: routes)
				close(client)
			}
		}
	}

	let port: UInt16

	func uri(
		_ path: String,
	) -> URI {
		.init(
			scheme: "http",
			authority: .init(host: "127.0.0.1", port: "\(port)"),
			path: path,
		)
	}

	private static func makeSocket(
	) -> Int32 {
		#if canImport(Darwin)
		socket(AF_INET, SOCK_STREAM, 0)
		#else
		socket(AF_INET, .init(SOCK_STREAM.rawValue), 0)
		#endif
	}

	private static func respond(
		_ client: Int32,
		routes: [String : Response],
	) {
		guard
			let path = readRequestPath(client),
			let response = routes[path]
		else {
			// 応答せず、相手が閉じるまで読み捨てる。
			var buffer: [UInt8] = .init(repeating: 0, count: 1024)

			while read(client, &buffer, buffer.count) > 0 {
			}

			return
		}

		let header: String
		= (
			[
				"HTTP/1.1 \(response.status) Test",
				"Content-Length: \(response.body.count)",
				"Connection: close",
			]
			+ response.headers
		)
		.map { $0 + "\r\n" }
		.joined()
		+ "\r\n"

		let bytes: [UInt8] = header.asBytes + response.body
		var offset: Int = 0

		while offset < bytes.count {
			let written: Int = bytes.withUnsafeBytes {
				write(client, $0.baseAddress! + offset, bytes.count - offset)
			}

			guard
				written > 0
			else { return }

			offset += written
		}
	}

	/// 要求行のパスを返す。ヘッダーの終わりまで読む。
	private static func readRequestPath(
		_ client: Int32,
	) -> String? {
		var request: [UInt8] = []
		var buffer: [UInt8] = .init(repeating: 0, count: 1024)
		let end: [UInt8] = "\r\n\r\n".asBytes

		while !request.ends(with: end) {
			let count: Int = read(client, &buffer, buffer.count)

			guard
				count > 0
			else { return nil }

			request += buffer.prefix(count)
		}

		let line: Substring? = String(decoding: request, as: UTF8.self)
			.split(separator: "\r\n")
			.first

		return line?.split(separator: " ").dropFirst().first.map(String.init)
	}

}


private extension Array where Element == UInt8 {

	func ends(
		with suffix: [UInt8],
	) -> Bool {
		count >= suffix.count && Array(self[(count - suffix.count)...]) == suffix
	}

}
#endif
