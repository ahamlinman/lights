import ArgumentParser

@main
struct Lights: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes across tools",
		subcommands: [Lights.Status.self, Lights.On.self, Lights.Off.self]
	)
}

extension Lights {
	struct Status: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Show the current color scheme"
		)

		func run() {
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
