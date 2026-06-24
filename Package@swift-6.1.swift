// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Swift 6.1+ toolchains select this manifest over `Package.swift`. It adds the
// `MultiSessionLogging` package trait (default OFF): when the trait is disabled, SwiftPM
// prunes Boutique (and its Bodega/SQLite/swift-collections chain) from the dependency graph
// entirely, so the watchOS build never compiles Bodega and Boutique stays out of
// `Package.resolved`. Enable the trait to get `MultiSessionLogger`'s Boutique-backed
// cross-launch persistence.
//
// `swiftLanguageModes: [.v5]` keeps the package in Swift 5 language mode. Without it, the
// 6.1 manifest would flip Broadcast to Swift 6 mode and turn the existing `static var`
// globals in `Log.swift` into hard concurrency errors on every platform; the pin makes this
// manifest *only* add the trait, matching the 5.10 manifest's semantics.
let package = Package(
	name: "Broadcast",
	platforms: [
		.iOS("18.0"),
		.macOS("15.0"),
		.watchOS("11.0"),
		.tvOS("18.0"),
		.visionOS("2.0")
	],
	products: [
		.library(
			name: "Broadcast",
			targets: ["Broadcast"]
		)
	],
	traits: [
		.trait(name: "MultiSessionLogging")
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
					condition: .when(traits: ["MultiSessionLogging"])
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
					condition: .when(traits: ["MultiSessionLogging"])
				)
			]
		)
	],
	swiftLanguageModes: [.v5]
)
