import ArgumentParser
import Foundation

@main
struct Lights: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes across tools",
		subcommands: [Lights.Status.self, Lights.On.self, Lights.Off.self]
	)

	static let baseDir = FileManager.default.homeDirectoryForCurrentUser
		.appending(component: ".lights")

	static let offDir = baseDir.appending(component: "off")
	static let onDir = baseDir.appending(component: "on")
	static let hooksDir = baseDir.appending(component: "hooks")
	static let currentLink = baseDir.appending(component: "current")

	static func ensureUserLightsTree() throws {
		for dir in [
			Lights.baseDir, Lights.offDir, Lights.onDir, Lights.hooksDir,
		] {
			try FileManager.default.createDirectory(
				at: dir, withIntermediateDirectories: true)
		}

		try? FileManager.default.createSymbolicLink(
			at: Lights.currentLink,
			withDestinationURL: Lights.offDir)
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
