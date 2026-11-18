@testable import Basis
import Libc


@Suite struct StandardStreamTests {

	/// 一時ファイルに書き込んだ内容を返す。
	private func written(
		_ body: (UnsafeMutablePointer<FILE>) -> Void,
	) throws -> String {
		let file: UnsafeMutablePointer<FILE> = try #require(tmpfile())
		defer { fclose(file) }

		body(file)

		fflush(file)
		rewind(file)

		var bytes: [UInt8] = []
		while true {
			let c = fgetc(file)
			if c == EOF { break }
			bytes.append(UInt8(c))
		}

		return bytes.asString
	}


	@Test func 文字列とバイト列を書き込む() throws {
		let result: String = try written { file in
			StandardStream.write(UnsafeRawBufferPointer(start: nil, count: 0), to: file)

			Array("日本語".utf8).withUnsafeBytes {
				StandardStream.write($0, to: file)
			}
		}

		#expect(result == "日本語")
	}


	@Test func 標準出力と標準エラー出力を区別する() {
		#expect(StandardStream.output != StandardStream.error)
		#expect(Backbone.outputStream == .output)
		#expect(Backbone.errorStream == .error)
	}


	@Test func printの出力先にできる() {
		var stream: StandardStream = Backbone.errorStream

		print("", terminator: "", to: &stream)
		stream.write("")
		stream.write([])
		stream.write(Binary())
		stream.flush()
	}

}
