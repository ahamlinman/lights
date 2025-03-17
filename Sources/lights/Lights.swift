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

struct Lights {
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

	static func flipLights(_ state: LightState) throws {
		try ensureUserLightsTree()
		try switchCurrentLink(to: state)
		try runAllHooks()
	}

	static func switchCurrentLink(to state: LightState) throws {
		let tmpdirURL = try FileManager.default.url(
			for: .itemReplacementDirectory, in: .userDomainMask,
			appropriateFor: Lights.currentLink, create: true)
		defer {
			try? FileManager.default.removeItem(at: tmpdirURL)
		}

		let newCurrentLink = tmpdirURL.appending(
			component: "lights-current", directoryHint: .notDirectory)
		let destination =
			switch state {
			case .on: Lights.onDir
			case .off: Lights.offDir
			}
		try FileManager.default.createSymbolicLink(
			at: newCurrentLink, withDestinationURL: destination)

		// I can't get replaceItem[At] to do what I want here.
		// They both complain that ~/.lights/current doesn't exist.
		let result = rename(
			newCurrentLink.relativePath, Lights.currentLink.relativePath)
		if result != 0 {
			throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
		}
	}

	static func runAllHooks() throws {
		for hookURL in try FileManager.default.contentsOfDirectory(
			at: Lights.hooksDir, includingPropertiesForKeys: nil)
		{
			do {
				try Process.run(hookURL, arguments: [])
				// TODO: Maybe I should set the output to /dev/null?
			} catch let err {
				print("Hook failed: \(err.localizedDescription)")
				// TODO: lights should exit with code 1 if any of these fail.
			}
		}
	}
}
