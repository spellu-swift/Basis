import Libc


///
/// ファイルを開いて、位置を指定して読むもの。
///
/// 大きなファイルの一部だけが要るときに使う。
/// 全体を読むなら ``File/load()`` を使う。
/// 読んだバイト列の解釈には ``BinaryReader`` を使う。
///
/// 読む位置を持たないので、複数のスレッドから同時に読める。
/// ファイルは、破棄するときに閉じる。
///
public final class FileReader : Sendable {

	///
	/// 読み取り用に開く。シンボリックリンクは辿る。
	///
	/// - Throws: ファイルが無ければ ``FileSystemError/missing(_:)``、
	///   通常のファイルでなければ ``FileSystemError/invalidType(_:)``、
	///   ほかの理由で開けなければ ``POSIXError``。
	///
	public init(
		_ file: File,
	) throws {
		let path: String
		= file.path.expanded

		// FIFO などを指定されても、開くところで待たされないようにする。
		// 開いたファイルは、子プロセスへ引き継がない。
		let descriptor: Int32
		= File.retryInterrupted {
			open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC)
		}

		guard
			descriptor != -1
		else {
			let error: Int32
			= errno

			guard
				error != ENOENT,
				error != ENOTDIR
			else { throw FileSystemError.missing(file) }

			throw POSIXError.system(error)
		}

		var status: stat
		= .init()

		guard
			File.retryInterrupted({ fstat(descriptor, &status) }) == 0
		else {
			let error: POSIXError
			= .system

			close(descriptor)

			throw error
		}

		guard
			status.st_mode & S_IFMT == S_IFREG
		else {
			close(descriptor)

			throw FileSystemError.invalidType(file)
		}

		self.file = file
		self.size = numericCast(status.st_size)
		self.descriptor = descriptor
	}

	deinit {
		close(descriptor)
	}

	/// 開いたファイル
	public let file: File

	/// 開いたときの、ファイルの大きさ（バイト数）
	public let size: Int64

	let descriptor: Int32

}


extension FileReader {

	///
	/// 位置を指定して読む。
	///
	/// ファイルの終わりを越える分は読まない。
	/// そのとき、返す長さは `count` より短くなる。
	/// `offset` がファイルの終わり以降なら、空を返す。
	///
	/// - Parameters:
	///   - offset: 読み始める位置。先頭が 0。負の値は指定できない。
	///   - count: 読むバイト数。負の値は指定できない。
	///
	public func read(
		at offset: Int64,
		count: Int,
	) throws -> Binary {
		try Self.read(
			at: offset,
			count: count,
		) { buffer, length, position in
			pread(descriptor, buffer, length, off_t(position))
		}
	}

}


extension FileReader {

	/// 1 回の読み取りで要求する、最大のバイト数
	static let chunkSize: Int
	= 64 * 1024

	///
	/// 割り込みと、要求より短い読み取りがあっても、指定した長さまで読む。
	/// 読み取りを差し替えられるようにしてある。
	///
	/// - Parameter read: バッファ、読むバイト数、読む位置を受け取り、
	///   読んだバイト数を返す。終わりは 0、失敗は負の値と `errno`。
	///
	static func read(
		at offset: Int64,
		count: Int,
		using read: (UnsafeMutableRawPointer, Int, Int64) -> Int,
	) throws -> Binary {
		precondition(offset >= 0 && count >= 0)

		var bytes: [UInt8]
		= []

		var chunk: [UInt8]
		= .init(repeating: 0, count: min(count, chunkSize))

		while bytes.count < count {
			let length: Int
			= min(chunk.count, count - bytes.count)

			let position: Int64
			= offset + Int64(bytes.count)

			let result: Int
			= chunk.withUnsafeMutableBytes {
				read($0.baseAddress!, length, position)
			}

			if result < 0 {
				let error: Int32
				= errno

				if error == EINTR {
					continue
				}

				throw POSIXError.system(error)
			}

			if result == 0 {
				break
			}

			bytes.append(contentsOf: chunk[..<result])
		}

		return Binary(bytes)
	}

}
