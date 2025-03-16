// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "Lights",
	platforms: [.macOS("13.0")],
	dependencies: [
		.package(
			url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"
		)
	],
	targets: [
		.executableTarget(
			name: "lights",
			dependencies: [
				.product(
					name: "ArgumentParser", package: "swift-argument-parser")
			],
			path: "Sources")
	]
)
