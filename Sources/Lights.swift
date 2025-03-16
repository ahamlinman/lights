import ArgumentParser
import Foundation

@main
struct Lights: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes across tools",
		subcommands: [Lights.Status.self, Lights.On.self, Lights.Off.self]
	)

	static let lightsDir = FileManager.default.homeDirectoryForCurrentUser
		.appending(component: ".lights")

	static let lightsOffDir = lightsDir.appending(components: "off")
	static let lightsOnDir = lightsDir.appending(components: "on")
	static let lightsCurrentLink = lightsDir.appending(components: "current")

	static func ensureUserLightsTree() throws {
		try FileManager.default.createDirectory(
			at: Lights.lightsDir, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(
			at: Lights.lightsOnDir,
			withIntermediateDirectories: true)
		try FileManager.default.createDirectory(
			at: Lights.lightsOffDir,
			withIntermediateDirectories: true)
		try? FileManager.default.createSymbolicLink(
			at: Lights.lightsCurrentLink,
			withDestinationURL: Lights.lightsOffDir)
	}
}

extension Lights {
	struct Status: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Show the current color scheme"
		)

		func run() throws {
			try ensureUserLightsTree()
			print("This command does nothing right now")
		}
	}

	struct On: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the light color scheme"
		)

		func run() {
			print("I wish I could turn the lights on for you")
		}
	}

	struct Off: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the dark color scheme"
		)

		func run() {
			print("I wish I could turn the lights off for you")
		}
	}
}
