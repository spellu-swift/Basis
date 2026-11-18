#if canImport(Darwin)
import Libc
#else
@preconcurrency import Libc
#endif


/// 標準出力・標準エラー出力へ書き込むストリーム。
///
/// `print`と同じCの`stdout`・`stderr`に書き込むため、`print`の出力と順番が入れ替わらない。
///
/// ```swift
/// StandardStream.error.write("エラー\n")
///
/// var stream: StandardStream = .error
/// print("エラー", to: &stream)
/// ```
public struct StandardStream : TextOutputStream, Sendable, Hashable {

	enum Target : Sendable, Hashable {
		case output
		case error
	}

	let target: Target

	/// 標準出力
	public static let output: StandardStream = .init(target: .output)

	/// 標準エラー出力
	public static let error: StandardStream = .init(target: .error)

	public func write(
		_ string: String,
	) {
		var string: String = string

		string.withUTF8 {
			Self.write(UnsafeRawBufferPointer($0), to: file)
		}
	}

	public func write(
		_ bytes: [UInt8],
	) {
		bytes.withUnsafeBytes {
			Self.write($0, to: file)
		}
	}

	@inlinable
	public func write(
		_ binary: Binary,
	) {
		write(binary.asBytes)
	}

	/// バッファに溜まっている内容を書き出す。
	public func flush(
	) {
		fflush(file)
	}

	private var file: UnsafeMutablePointer<FILE> {
		switch target {
			case .output:
				stdout
			case .error:
				stderr
		}
	}

	static func write(
		_ buffer: UnsafeRawBufferPointer,
		to file: UnsafeMutablePointer<FILE>,
	) {
		guard
			let base = buffer.baseAddress,
			buffer.count > 0
		else { return }

		fwrite(base, 1, buffer.count, file)
	}

}
