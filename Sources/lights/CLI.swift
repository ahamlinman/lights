import ArgumentParser
import Foundation

@main
struct CLI: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes",
		subcommands: [CLI.Status.self, CLI.On.self, CLI.Off.self],
		defaultSubcommand: CLI.Status.self
	)

	static let baseDir = FileManager.default.homeDirectoryForCurrentUser
		.appending(component: ".lights", directoryHint: .isDirectory)
}

extension CLI {
	struct Status: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Show the current color scheme"
		)

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			let state = try lights.state()
			print(state.name)
		}
	}

	struct On: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the light color scheme"
		)

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			try lights.flip(.on)
		}
	}

	struct Off: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the dark color scheme"
		)

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			try lights.flip(.off)
		}
	}
}
