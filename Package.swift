// swift-tools-version:6.1
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
	traits: [
		.trait(
			name: "MultiSessionLogging",
			description: "Enables MultiSessionLogger for persisting logs across launches."
		),
		.default(enabledTraits: ["MultiSessionLogging"]),
		.trait(
			name: "SwiftLogging",
			description: "Enables SwiftLogDestination for forwarding Broadcast records to swift-log."
		)
	],
	dependencies: [
		.package(url: "https://github.com/mergesort/Boutique", from: Version(3, 0, 2)),
		.package(url: "https://github.com/apple/swift-log", from: Version(1, 6, 0)),
		.package(url: "https://github.com/apple/swift-docc-plugin", from: Version(1, 0, 0))
	],
	targets: [
		.target(
			name: "Broadcast",
			dependencies: [
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS], traits: ["MultiSessionLogging"])
				),
				.product(name: "Logging", package: "swift-log", condition: .when(traits: ["SwiftLogging"]))
			]
		),
		.testTarget(
			name: "BroadcastTests",
			dependencies: [
				.product(
					name: "Boutique",
					package: "Boutique",
					condition: .when(platforms: [.iOS, .macOS], traits: ["MultiSessionLogging"])
				),
				.product(name: "Logging", package: "swift-log", condition: .when(traits: ["SwiftLogging"])),
				"Broadcast"
			]
		)
	],
	swiftLanguageModes: [.v5]
)
