import ArgumentParser
import Foundation

@main struct CLI: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "lights",
		abstract: "Switch between dark and light color schemes",
		subcommands: [CLI.Status.self, CLI.Off.self, CLI.On.self],
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
			let lights = Lights(baseDir: CLI.baseDir)
			if let power = lights.power { print(power) } else { throw NotInitializedError() }

			struct NotInitializedError: Error, CustomStringConvertible {
				let description =
					"The lights configuration is not initialized. Run `lights off` or `lights on`."
			}
		}
	}

	struct Off: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Switch to dark colors")

		func run() throws {
			let lights = Lights(baseDir: CLI.baseDir)
			try lights.flip(.off)
		}
	}

	struct On: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Switch to light colors")

		func run() throws {
			let lights = Lights(baseDir: CLI.baseDir)
			try lights.flip(.on)
		}
	}
}
