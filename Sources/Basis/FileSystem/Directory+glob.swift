// NOTE: MacOS標準実装のglobは、「プ」を含むファイルパスを処理できず、error=3を返してくる。
//
//
//extension Directory {
//	
//	/// ディレクトリ下のエントリをパターンマッチする
//	public func glob(
//		_ pattern: String,
//	) throws -> [FilePath] {
//		try POSIX.glob(
//			directory: path.expanded,
//			pattern: pattern,
//		)
//		.map {
//			path[$0]
//		}
//	}
//	
//}
