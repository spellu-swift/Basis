// swift-tools-version: 6.0
import PackageDescription


// guioa のリポジトリに格納した SwiftSyntax を、pkg-config で参照する。
//
// Basis のパッケージに置かず、別のパッケージにしている。
// Swift Build は、マクロから同じパッケージの systemLibrary への依存を
// 解決できない（missing target with GUID 'PACKAGE-TARGET:SwiftSyntax'）。
let package = Package(
	name: "SwiftSyntaxBinary",
	products: [
		.library(
			name: "SwiftSyntax",
			targets: ["SwiftSyntax"],
		),
	],

	targets: [
		.systemLibrary(
			name: "SwiftSyntax",
			pkgConfig: "SwiftSyntax",
		),
	],
)
