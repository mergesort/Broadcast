// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// brightdigit/atleast fork for AtLeast (a watchOS-first app).
//
// `MultiSessionLogger` and its Boutique-backed cross-launch persistence are kept.
// Boutique's chain (Bodega/SQLite/swift-collections) does not declare watchOS, so
// under some Xcode 27 betas Tuist generated those targets with
// WATCHOS_DEPLOYMENT_TARGET=8.0 and the watchOS build failed; if that resurfaces,
// override the floor via the app's Tuist PackageSettings rather than dropping the
// logger. watchOS/tvOS/visionOS floors match `Synchronization.Mutex`.
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
		.package(url: "https://github.com/mergesort/Boutique", from: Version(3, 0, 2))
	],
	targets: [
		.target(
			name: "Broadcast",
			dependencies: [
				.product(name: "Boutique", package: "Boutique")
			]
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: [
				.product(name: "Boutique", package: "Boutique"),
				"Broadcast"
			]
		)
	]
)
