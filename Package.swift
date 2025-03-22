// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "lights",
	platforms: [.macOS(.v13)],
	products: [
		.library(name: "LightsKit", targets: ["LightsKit"]),
		.executable(name: "lights", targets: ["lights"]),
	],
	dependencies: [.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")],
	targets: [
		.target(name: "LightsKit", dependencies: []),
		.executableTarget(
			name: "lights",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.target(name: "LightsKit"),
			]
		),
	]
)
