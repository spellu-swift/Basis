@testable import Basis
import Libc


@Suite struct FileReaderTests {

	/// 0, 1, 2, … と並ぶ、長さ `count` のバイト列
	static func sequence(
		_ count: Int,
	) -> [UInt8] {
		(0 ..< count).map { UInt8(truncatingIfNeeded: $0) }
	}


	// MARK: - init


	@Test
	func initは通常のファイルを開く(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary(Self.sequence(10)))

			let reader: FileReader
			= try .init(file)

			#expect(reader.file.path == file.path)
			#expect(reader.size == 10)
			#expect(try reader.read(at: 0, count: 10).asBytes == Self.sequence(10))
		}
	}


	@Test
	func initはシンボリックリンクを辿る(
	) throws {
		try Directory.withTemporary { directory in
			let target: File
			= directory[file: "target"]

			let link: File
			= directory[file: "link"]

			try target.save("original")
			try link.createSymlink(of: target.path)

			let reader: FileReader
			= try .init(link)

			#expect(reader.file.path == link.path)
			#expect(reader.size == 8)
			#expect(try reader.read(at: 0, count: 8).asString == "original")
		}
	}


	@Test
	func initは無いファイルをmissingにする(
	) throws {
		try Directory.withTemporary { directory in
			let missing: File
			= directory[file: "missing"]

			#expect(throws: FileSystemError.missing(missing)) {
				_ = try FileReader(missing)
			}

			// 途中のディレクトリが無い
			let nested: File
			= directory[file: "missing/data"]

			#expect(throws: FileSystemError.missing(nested)) {
				_ = try FileReader(nested)
			}

			// 途中がディレクトリでない
			try directory[file: "data"].save("x")

			let below: File
			= directory[file: "data/below"]

			#expect(throws: FileSystemError.missing(below)) {
				_ = try FileReader(below)
			}

			// リンク先が無いシンボリックリンク
			let dangling: File
			= directory[file: "dangling"]

			try dangling.createSymlink(of: missing.path)

			#expect(throws: FileSystemError.missing(dangling)) {
				_ = try FileReader(dangling)
			}
		}
	}


	@Test
	func initはディレクトリをinvalidTypeにする(
	) throws {
		try Directory.withTemporary { directory in
			try directory.createDirectory("sub")

			let file: File
			= directory[file: "sub"]

			#expect(throws: FileSystemError.invalidType(file)) {
				_ = try FileReader(file)
			}
		}
	}


	@Test
	func initはFIFOを待たずにinvalidTypeにする(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "fifo"]

			#expect(mkfifo(file.path.asString, 0o600) == 0)

			// 書き手がいなくても、開くところで止まらない。
			#expect(throws: FileSystemError.invalidType(file)) {
				_ = try FileReader(file)
			}
		}
	}


	@Test(.enabled(if: geteuid() != 0, "root は権限に関わらず読める"))
	func initは読めないファイルをPOSIXErrorにする(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "secret"]

			try file.save("x")
			try file.setPermissions(0o000)

			#expect(throws: POSIXError.system(EACCES)) {
				_ = try FileReader(file)
			}
		}
	}


	// MARK: - size


	@Test
	func sizeは開いたときの大きさ(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary([]))

			let empty: FileReader
			= try .init(file)

			#expect(empty.size == 0)

			// 開いた後に書き換えても、size は変わらない。内容は新しいものが読める。
			try file.save(Binary(Self.sequence(5)))

			#expect(empty.size == 0)
			#expect(try empty.read(at: 0, count: 10).asBytes == Self.sequence(5))

			#expect(try FileReader(file).size == 5)
		}
	}


	// MARK: - read(at:count:)


	@Test
	func readは指定した位置から読む(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary(Self.sequence(10)))

			let reader: FileReader
			= try .init(file)

			// 先頭
			#expect(try reader.read(at: 0, count: 4).asBytes == [0, 1, 2, 3])

			// 途中
			#expect(try reader.read(at: 3, count: 4).asBytes == [3, 4, 5, 6])

			// 終わりまでちょうど
			#expect(try reader.read(at: 6, count: 4).asBytes == [6, 7, 8, 9])

			// 最後の 1 バイト
			#expect(try reader.read(at: 9, count: 1).asBytes == [9])
		}
	}


	@Test
	func readは読む位置を持たない(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary(Self.sequence(10)))

			let reader: FileReader
			= try .init(file)

			// 後ろを読んでから前を読める。同じ場所を何度でも読める。
			#expect(try reader.read(at: 8, count: 2).asBytes == [8, 9])
			#expect(try reader.read(at: 0, count: 2).asBytes == [0, 1])
			#expect(try reader.read(at: 0, count: 2).asBytes == [0, 1])
		}
	}


	@Test
	func readはファイルの終わりを越える分を読まない(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary(Self.sequence(10)))

			let reader: FileReader
			= try .init(file)

			// 終わりをまたぐ
			#expect(try reader.read(at: 8, count: 4).asBytes == [8, 9])

			// 全体より長く
			#expect(try reader.read(at: 0, count: 100).asBytes == Self.sequence(10))

			// 終わりの位置
			#expect(try reader.read(at: 10, count: 4).asBytes.isEmpty)

			// 終わりより後ろ
			#expect(try reader.read(at: 1000, count: 4).asBytes.isEmpty)
		}
	}


	@Test
	func readはcountが0なら空を返す(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary(Self.sequence(10)))

			let reader: FileReader
			= try .init(file)

			#expect(try reader.read(at: 0, count: 0).asBytes.isEmpty)
			#expect(try reader.read(at: 5, count: 0).asBytes.isEmpty)
			#expect(try reader.read(at: 10, count: 0).asBytes.isEmpty)
		}
	}


	@Test
	func readは空のファイルから空を返す(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save(Binary([]))

			let reader: FileReader
			= try .init(file)

			#expect(try reader.read(at: 0, count: 16).asBytes.isEmpty)
		}
	}


	@Test
	func readは1回の読み取りより大きい範囲を読む(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			let bytes: [UInt8]
			= Self.sequence(200_000)

			try file.save(Binary(bytes))

			let reader: FileReader
			= try .init(file)

			#expect(150_000 > FileReader.chunkSize * 2)

			#expect(
				try reader.read(at: 1_000, count: 150_000).asBytes
				== Array(bytes[1_000 ..< 151_000])
			)

			// 1 回の読み取りの大きさと、その前後
			for count in [
				FileReader.chunkSize - 1,
				FileReader.chunkSize,
				FileReader.chunkSize + 1,
			] {
				#expect(
					try reader.read(at: 7, count: count).asBytes
					== Array(bytes[7 ..< 7 + count])
				)
			}

			// 全体
			#expect(try reader.read(at: 0, count: 200_000).asBytes == bytes)
		}
	}


	@Test
	func readは置き換えられた後も開いたファイルを読む(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			try file.save("original")

			let reader: FileReader
			= try .init(file)

			// 別のファイルに置き換える。
			try file.saveAtomically("replacement")

			#expect(try reader.read(at: 0, count: 100).asString == "original")
			#expect(try FileReader(file).read(at: 0, count: 100).asString == "replacement")

			// 削除する。
			try file.delete()

			#expect(try reader.read(at: 0, count: 100).asString == "original")
		}
	}


	@Test
	func readの結果をBinaryReaderで解釈する(
	) throws {
		try Directory.withTemporary { directory in
			let file: File
			= directory[file: "data"]

			// 先頭に目印、16 バイト目から 2 つの値がある。
			var bytes: [UInt8]
			= .init(repeating: 0xEE, count: 32)

			bytes.replaceSubrange(0 ..< 4, with: [0x7F, 0x45, 0x4C, 0x46])
			bytes.replaceSubrange(16 ..< 20, with: [0x03, 0x00, 0x3E, 0x00])

			try file.save(Binary(bytes))

			let reader: FileReader
			= try .init(file)

			#expect(try reader.read(at: 0, count: 4).asBytes == [0x7F, 0x45, 0x4C, 0x46])

			let fields: BinaryReader
			= .init(try reader.read(at: 16, count: 4))

			#expect(try fields.readUInt16(.little) == 3)
			#expect(try fields.readUInt16(.little) == 62)
			#expect(fields.remain == 0)
		}
	}


	// MARK: - read(at:count:using:)


	@Test
	func 割り込みと短い読み取りがあっても指定した長さまで読む(
	) throws {
		let input: [UInt8]
		= [10, 11, 12, 13, 14, 15, 16, 17]

		var calls: Int
		= 0

		var positions: [Int64]
		= []

		let result: Binary
		= try FileReader.read(at: 2, count: 5) { buffer, length, position in
			calls += 1

			if calls == 1 || calls == 3 {
				errno = EINTR
				return -1
			}

			positions.append(position)

			// 1 回に 2 バイトまでしか返さない。
			let count: Int
			= min(2, length)

			for index in 0 ..< count {
				buffer.storeBytes(
					of: input[Int(position) + index],
					toByteOffset: index,
					as: UInt8.self,
				)
			}

			return count
		}

		#expect(result.asBytes == [12, 13, 14, 15, 16])

		// 割り込まれた回は、同じ位置からやり直す。
		#expect(positions == [2, 4, 6])
		#expect(calls == 5)
	}


	@Test
	func 終わりに達したらそこまでを返す(
	) throws {
		var calls: Int
		= 0

		let result: Binary
		= try FileReader.read(at: 0, count: 10) { buffer, _, _ in
			calls += 1

			guard
				calls == 1
			else { return 0 }

			buffer.storeBytes(of: 7, as: UInt8.self)

			return 1
		}

		#expect(result.asBytes == [7])
		#expect(calls == 2)
	}


	@Test
	func 要求は残りの長さと1回の最大を越えない(
	) throws {
		var lengths: [Int]
		= []

		let count: Int
		= FileReader.chunkSize * 2 + 10

		let result: Binary
		= try FileReader.read(at: 0, count: count) { _, length, _ in
			lengths.append(length)

			return length
		}

		#expect(result.count == count)
		#expect(lengths == [FileReader.chunkSize, FileReader.chunkSize, 10])
	}


	@Test
	func countが0なら読み取りを呼ばない(
	) throws {
		var calls: Int
		= 0

		let result: Binary
		= try FileReader.read(at: 0, count: 0) { _, _, _ in
			calls += 1

			return 0
		}

		#expect(result.asBytes.isEmpty)
		#expect(calls == 0)
	}


	@Test
	func 読み取りの失敗はPOSIXErrorにする(
	) {
		#expect(throws: POSIXError.system(EIO)) {
			try FileReader.read(at: 0, count: 4) { _, _, _ in
				errno = EIO
				return -1
			}
		}

		// 途中まで読めていても、失敗にする。
		var calls: Int
		= 0

		#expect(throws: POSIXError.system(EBADF)) {
			try FileReader.read(at: 0, count: 4) { _, _, _ in
				calls += 1

				guard
					calls > 1
				else { return 1 }

				errno = EBADF
				return -1
			}
		}
	}

}
