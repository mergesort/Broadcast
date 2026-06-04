// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
