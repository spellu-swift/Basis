// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport


#if canImport(Glibc)
let basisCSettings: [PackageDescription.CSetting]? = [
	// glibcは_GNU_SOURCEなどを定義しないとstrptimeを宣言しない。
	.define("_GNU_SOURCE", .when(platforms: [.linux])),
]
#else
let basisCSettings: [PackageDescription.CSetting]? = nil
#endif


let package = Package(
	name: "Basis",
	platforms: [
		.macOS(.v14),
		.iOS(.v17),
	],
	products: [
		.library(
			name: "Basis",
			targets: ["Basis", "Libc", "BigInt", "BigDecimal", "BasisUtility", "BasisExperimental"],
		),
		.library(
			name: "BasisUtility",
			targets: ["BasisUtility"],
		),
		.library(
			name: "Logging",
			targets: ["Logging"],
		),
		.library(
			name: "SwiftMacro",
			targets: ["SwiftMacro"],
		),
		.library(
			name: "Testing",
			targets: ["UnitTesting", "MacroTesting"],
		),
	],

	dependencies: [
		.package(name: "SwiftSyntaxBinary", path: "Binaries/SwiftSyntax"),
	],

	targets: [
		.target(
			name: "Basis",
			dependencies: ["Libc", "BasisMacros"],
			cSettings: basisCSettings,
		),
		.testTarget(
			name: "BasisTests",
			dependencies: ["Basis", "UnitTesting"],
		),
		
		.target(
			name: "Libc",
			dependencies: [],
		),
		.testTarget(
			name: "LibcTests",
			dependencies: ["Libc", "UnitTesting"],
		),

		.target(
			name: "BigInt",
			dependencies: [],
		),
		.testTarget(
			name: "BigIntTests",
			dependencies: ["BigInt", "UnitTesting"],
			exclude: ["Vectors.py"],
		),

		.target(
			name: "BigDecimal",
			dependencies: ["BigInt"],
		),
		.testTarget(
			name: "BigDecimalTests",
			dependencies: ["BigDecimal", "UnitTesting"],
			exclude: ["Vectors.py"],
		),

		.target(
			name: "Logging",
			dependencies: ["Basis"],
		),

		.target(
			name: "BasisUtility",
			dependencies: ["Basis"],
		),
		.testTarget(
			name: "BasisUtilityTests",
			dependencies: ["BasisUtility", "UnitTesting"],
		),

		.target(
			name: "BasisExperimental",
			dependencies: ["Basis"],
		),
		.testTarget(
			name: "BasisExperimentalTests",
			dependencies: ["BasisExperimental", "UnitTesting"],
		),

		.target(
			name: "SwiftMacro",
			dependencies: [.product(name: "SwiftSyntax", package: "SwiftSyntaxBinary")],
		),

		.macro(
			name: "BasisMacros",
			dependencies: [.product(name: "SwiftSyntax", package: "SwiftSyntaxBinary")],
		),
		.testTarget(
			name: "BasisMacrosTests",
			dependencies: [
				"BasisMacros",
				"MacroTesting",
			],
		),
		
		.target(
			name: "UnitTesting",
			dependencies: [
				"Basis",
			],
		),
		.target(
			name: "MacroTesting",
			dependencies: [
				"UnitTesting",
				.product(name: "SwiftSyntax", package: "SwiftSyntaxBinary"),
			],
		),
	],
)
