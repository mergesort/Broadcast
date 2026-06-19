// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// brightdigit/atleast fork: trimmed for AtLeast (a watchOS-first app).
//
// The `MultiSessionLogger` destination and its Boutique-backed cross-launch
// persistence are removed here — AtLeast uses `ConsoleLogger` + `SessionLogger`
// only, and Boutique's chain (Bodega/SQLite/swift-collections) does not declare
// watchOS support. Dropping it leaves Broadcast dependency-free and lets it
// build for watchOS. watchOS/tvOS/visionOS floors match `Synchronization.Mutex`.
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
