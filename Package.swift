// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// brightdigit/atleast fork for AtLeast (a watchOS-first app).
//
// `MultiSessionLogger` and its Boutique-backed cross-launch persistence live behind the
// `MultiSessionLogging` package trait, declared in `Package@swift-6.1.swift` (traits need
// swift-tools 6.1+). This 5.10 manifest is the fallback for older toolchains: its only
// dependency is swift-docc-plugin (a build-tool plugin that never links into the product),
// and `MultiSessionLogger` (guarded by `#if MultiSessionLogging`) compiles to nothing because
// the trait flag is never set here.
//
// Why the trait: Boutique's chain (Bodega/SQLite/swift-collections) does not declare
// watchOS, so when a build assigns those targets a watchOS floor below 9.0 (Xcode-version
// dependent), Bodega's `URL.documentsDirectory`/`.cachesDirectory` usage fails to compile.
// Keeping Boutique off the graph by default makes the watch build clean; consumers that want
// the logger enable the trait. watchOS/tvOS/visionOS floors match `Synchronization.Mutex`.
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
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: Version(1, 0, 0))
	],
	targets: [
		.target(
			name: "Broadcast"
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: [
				"Broadcast"
			]
		)
	]
)
