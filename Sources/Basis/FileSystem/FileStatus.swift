import Libc


/// ファイルの状態。パスが存在しない場合は作れない。
public struct FileStatus {
	
	public init?(
		at path: FilePath,
		followLink: Bool,
	) {
		self.init(
			at: path.asString,
			followLink: followLink
		)
	}

	public init?(
		at path: String,
		followLink: Bool,
	) {
		var status: stat = .init()
		
		guard lstat(path, &status) == 0 else { return nil }

		if status.st_mode & S_IFMT == S_IFLNK {
			if followLink {
				status = .init()
				stat(path, &status)
			}

			self.symlink = true
		}
		else {
			self.symlink = false
		}
		
		self.raw = status
	}
	
	public let symlink: Bool
	
	public let raw: stat
	
	/// リンク先が存在しないシンボリックリンクをたどった場合はnil
	public var type: FileType? {
		switch raw.st_mode & S_IFMT {
			case 0:
				return .none
			case S_IFREG:
				return .file
			case S_IFDIR:
				return .directory
			case S_IFLNK:
				return .link
			case S_IFIFO:
				return .fifo
			case S_IFCHR:
				return .character
			case S_IFBLK:
				return .block
			case S_IFSOCK:
				return .socket
//			case S_IFWHT:
//				return .wht
			default:
				return .unknown
		}
	}
	
	@inlinable
	public var permissions: FilePermissions {
		FilePermissions(mode: raw.st_mode)
	}
	
	@inlinable
	public var size: Int64 {
		numericCast(raw.st_size)
	}
	
	@inlinable
	public var accessTime: ClockTime {
#if canImport(Darwin)
		.clock(raw.st_atimespec.tv_sec)
#else
		.clock(raw.st_atim.tv_sec)
#endif
	}
		
	@inlinable
	public var modificationTime: ClockTime {
#if canImport(Darwin)
		.clock(raw.st_mtimespec.tv_sec)
#else
		.clock(raw.st_mtim.tv_sec)
#endif
	}

#if canImport(Darwin)
	@inlinable
	public var creationTime: ClockTime {
		.clock(raw.st_birthtimespec.tv_sec)
	}
#endif
	
}


// MARK: - Identity


extension FileStatus {

	/// 同じ実物（ファイル、ディレクトリなど）を指しているか。
	///
	/// デバイス番号（`st_dev`）とinode番号（`st_ino`）を比べる。
	///
	/// - 別のパスでも、同じ実物を指すハードリンクならtrueになる。
	/// - シンボリックリンクは、作るときの`followLink`の指定で、
	///   リンクそのものとリンク先のどちらを比べるかが変わる。
	///   比べる2つは、同じ指定で作ること。
	/// - 状態は作った時点のもの。比べた後に置き換わることは防げない。
	@inlinable
	public func isSame(
		as other: FileStatus,
	) -> Bool {
		raw.st_dev == other.raw.st_dev
			&& raw.st_ino == other.raw.st_ino
	}

}
