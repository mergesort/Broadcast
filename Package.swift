// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Broadcast requires Swift 6.0+: it uses `Synchronization.Mutex` and, on non-Apple platforms,
// `Foundation.FormatStyle` — both of which only exist in the Swift 6.0 toolchain on Linux.
//
// Boutique (and its Bodega/SQLite/swift-collections chain) imports `CryptoKit`, which is
// unavailable on non-Apple platforms, so its *target* dependency is gated to Apple platforms
// with `.when(platforms:)`. On Linux SwiftPM still resolves Boutique but never compiles it,
// and `MultiSessionLogger` (guarded by `#if canImport(Boutique)`) compiles to nothing.
// `ConsoleLogger` is likewise gated on `#if canImport(OSLog)`.
//
// `swiftLanguageModes: [.v5]` keeps Swift 5 language mode so existing `static var` globals do
// not become hard concurrency errors under Swift 6 mode.
let package = Package(
	name: "Broadcast",
	platforms: [
		.iOS("18.0"),
		.macOS("15.0")
	],
	products: [
		.library(
			name: "Broadcast",
			targets: ["Broadcast"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/mergesort/Boutique", from: Version(3, 0, 2)),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: Version(1, 0, 0))
	],
	targets: [
		.target(
			name: "Broadcast",
			dependencies: [
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS, .tvOS, .watchOS, .visionOS])
				)
			]
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: [
				"Broadcast",
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS, .tvOS, .watchOS, .visionOS])
				)
			]
		)
	],
	swiftLanguageModes: [.v5]
)
