

extension URI {

	/// 基底URIへ再解決すると、ドットセグメント除去後の自身になる参照を返す。
	/// 両者にスキームが必要。相対参照で表せなければ絶対URIを返す。
	public func relative(
		to base: URI,
	) -> URI? {
		guard
			isAbsolute,
			base.isAbsolute
		else { return nil }

		let target: URI
		= removingDotSegments()

		guard
			target.scheme == base.scheme
		else { return target }

		if target.authority == base.authority {
			// 同じパスとクエリは基底から継承し、fragmentだけを差し替える。
			let empty: URI
			= .init(
				path: "",
				query: target.query == base.query ? nil : target.query,
				fragment: target.fragment,
			)

			if empty.resolved(against: base) == target { return empty }

			let directory: String
			if base.authority != nil && base.path.isEmpty {
				directory = "/"
			}
			else if let slash = base.path.lastIndex(of: "/") {
				directory = Self.removeDotSegments(String(base.path[...slash]))
			}
			else {
				directory = ""
			}

			let directories: [String]
			= directory.isEmpty ? [] : directory.split(
				separator: "/",
				omittingEmptySubsequences: false,
			).dropLast().map(String.init)

			let segments: [String]
			= target.path.split(
				separator: "/",
				omittingEmptySubsequences: false,
			).map(String.init)

			var common: Int = 0
			while common < directories.count && common < segments.count - 1 &&
				directories[common] == segments[common]
			{
				common += 1
			}

			var path: String
			= (Array(repeating: "..", count: directories.count - common) + segments.dropFirst(common))
				.joined(separator: "/")

			// 空のディレクトリ要素が先頭に残っても、絶対パスにはしない。
			if path.isEmpty || path.hasPrefix("/") { path = "./" + path }

			var reference: URI
			= .init(path: path, query: target.query, fragment: target.fragment)
			reference.protectPathSyntax()

			if reference.resolved(against: base) == target { return reference }

			// ルートを持たないパスなど、上記の相対パスで表せない場合に備える。
			reference.path = target.path
			reference.protectPathSyntax()
			if reference.resolved(against: base) == target { return reference }
		}

		if target.authority != nil {
			var reference: URI = target
			reference.scheme = nil
			if reference.resolved(against: base) == target { return reference }
		}

		return target
	}

}
