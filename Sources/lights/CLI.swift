import ArgumentParser
import Foundation

@main struct CLI: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes",
		subcommands: [CLI.Status.self, CLI.On.self, CLI.Off.self],
		defaultSubcommand: CLI.Status.self
	)

	static let baseDir = FileManager.default.homeDirectoryForCurrentUser.appending(
		component: ".lights",
		directoryHint: .isDirectory
	)
}

extension CLI {
	struct Status: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Print the current color scheme")

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			if let power = lights.power() { print(power) } else { throw NotInitializedError() }
		}
	}

	struct On: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Switch to light colors")

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			try lights.flip(.on)
		}
	}

	struct Off: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Switch to dark colors")

		func run() throws {
			let lights = try Lights(baseDir: CLI.baseDir)
			try lights.flip(.off)
		}
	}
}

struct NotInitializedError: Error, CustomStringConvertible {
	var description: String {
		"The lights configuration is not initialized. Run `lights on` or `lights off`."
	}
}
