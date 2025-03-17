import ArgumentParser
import Foundation

enum LightState {
	case off, on

	var name: String {
		switch self {
		case .off: return "off"
		case .on: return "on"
		}
	}
}

enum LightsError: Error, CustomStringConvertible {
	case badCurrentLink(target: URL)

	var description: String {
		switch self {
		case let .badCurrentLink(target):
			return
				"The current lights link points to \(target.absoluteString), not a lights config directory."
		}
	}
}

@main
struct Lights: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Switch between light and dark color schemes across tools",
		subcommands: [Lights.Status.self, Lights.On.self, Lights.Off.self],
		defaultSubcommand: Lights.Status.self
	)

	static let baseDir = FileManager.default.homeDirectoryForCurrentUser
		.appending(component: ".lights", directoryHint: .isDirectory)

	static let offDir = baseDir.appending(
		component: "off", directoryHint: .isDirectory)
	static let onDir = baseDir.appending(
		component: "on", directoryHint: .isDirectory)
	static let hooksDir = baseDir.appending(
		component: "hooks", directoryHint: .isDirectory)
	static let currentLink = baseDir.appending(
		component: "current", directoryHint: .notDirectory)

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

	static func currentState() throws -> LightState {
		let targetPath = try FileManager.default.destinationOfSymbolicLink(
			atPath: Lights.currentLink.relativePath)
		let targetURL = URL(filePath: targetPath, relativeTo: Lights.baseDir)
		switch targetURL.lastPathComponent {
		case "off":
			return .off
		case "on":
			return .on
		default:
			throw LightsError.badCurrentLink(target: targetURL)
		}
	}

	static func switchLights(to state: LightState) throws {
		let tempLinkDir = try FileManager.default.url(
			for: .itemReplacementDirectory, in: .userDomainMask,
			appropriateFor: Lights.currentLink, create: true)
		defer {
			try? FileManager.default.removeItem(at: tempLinkDir)
		}

		let tempLink = tempLinkDir.appending(
			component: "lights-current", directoryHint: .notDirectory)
		let destination =
			switch state {
			case .on: Lights.onDir
			case .off: Lights.offDir
			}
		try FileManager.default.createSymbolicLink(
			at: tempLink, withDestinationURL: destination)

		let result = rename(
			tempLink.relativePath, Lights.currentLink.relativePath)
		if result != 0 {
			throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
		}
	}
}

extension Lights {
	struct Status: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Show the current color scheme"
		)

		func run() throws {
			try ensureUserLightsTree()
			let state = try currentState()
			print(state.name)
		}
	}

	struct On: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the light color scheme"
		)

		func run() throws {
			try switchLights(to: .on)
		}
	}

	struct Off: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Switch to the dark color scheme"
		)

		func run() throws {
			try switchLights(to: .off)
		}
	}
}
