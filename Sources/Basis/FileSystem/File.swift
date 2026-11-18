import Libc


///
/// ファイル
///
public struct File : Sendable {

	@inlinable
	public init(
		at components: String?...,
	) {
		self.path = FilePath(components.compacted())
	}
	
	@inlinable
	public init(
		at components: [String],
	) {
		self.path = FilePath(components)
	}
	
	@inlinable
	public init(
		at path: FilePath,
	) {
		self.path = path
	}
	
	public var path: FilePath
	
	@inlinable
	public var absoluted: File {
		.init(at: path.absoluted)
	}
	
	@inlinable
	public func absoluted(
		relativeTo base: String,
		as kind: FilePath.Kind? = nil,
	) -> File {
		.init(at: path.absoluted(relativeTo: base, as: kind))
	}

	@inlinable
	public func absoluted(
		relativeTo base: FilePath,
		as kind: FilePath.Kind? = nil,
	) -> File {
		.init(at: path.absoluted(relativeTo: base, as: kind))
	}

	@inlinable
	public var parent: Directory {
		Directory(
			at: path.parent
		)
	}
	
}


extension File {
	
	/// ファイルの内容のバイナリ表現
	@inlinable
	public var binary: Binary {
		get throws {
			try load()
		}
	}

	/// ファイルの内容のテキスト表現
	@inlinable
	public var text: String {
		get throws {
			try load().asString
		}
	}

	/// ファイルの内容の行分割テキスト表現
	/// 改行コードは "\n", "\r\n" を扱える。
	public var lines: [Substring] {
		get throws {
			try text.split(separator: "\n", omittingEmptySubsequences: false)
		}
	}

}


