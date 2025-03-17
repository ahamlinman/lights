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
	let baseDir: URL

	var offDir: URL {
		baseDir.appending(
			component: "off", directoryHint: .isDirectory)
	}
	var onDir: URL {
		baseDir.appending(
			component: "on", directoryHint: .isDirectory)
	}
	var hooksDir: URL {
		baseDir.appending(
			component: "hooks", directoryHint: .isDirectory)
	}
	var currentLink: URL {
		baseDir.appending(
			component: "current", directoryHint: .notDirectory)
	}

	init(baseDir: URL) throws {
		self.baseDir = baseDir

		for dir in [
			self.baseDir, self.offDir, self.onDir, self.hooksDir,
		] {
			try FileManager.default.createDirectory(
				at: dir, withIntermediateDirectories: true)
		}

		try? FileManager.default.createSymbolicLink(
			at: self.currentLink, withDestinationURL: self.offDir)
	}

	func state() throws -> LightState {
		let targetPath = try FileManager.default.destinationOfSymbolicLink(
			atPath: self.currentLink.relativePath)
		let targetURL = URL(filePath: targetPath, relativeTo: self.baseDir)
		switch targetURL.lastPathComponent {
		case "off":
			return .off
		case "on":
			return .on
		default:
			throw LightsError.badCurrentLink(target: targetURL)
		}
	}

	func flip(_ state: LightState) throws {
		try switchCurrentLink(to: state)
		try runAllHooks()
	}

	func switchCurrentLink(to state: LightState) throws {
		let tmpdirURL = try FileManager.default.url(
			for: .itemReplacementDirectory, in: .userDomainMask,
			appropriateFor: self.currentLink, create: true)
		defer {
			try? FileManager.default.removeItem(at: tmpdirURL)
		}

		let newCurrentLink = tmpdirURL.appending(
			component: "lights-current", directoryHint: .notDirectory)
		let destination =
			switch state {
			case .on: self.onDir
			case .off: self.offDir
			}
		try FileManager.default.createSymbolicLink(
			at: newCurrentLink, withDestinationURL: destination)

		// I can't get replaceItem[At] to do what I want here.
		// They both complain that ~/.lights/current doesn't exist.
		let result = rename(
			newCurrentLink.relativePath, self.currentLink.relativePath)
		if result != 0 {
			throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
		}
	}

	func runAllHooks() throws {
		for hookURL in try FileManager.default.contentsOfDirectory(
			at: self.hooksDir, includingPropertiesForKeys: nil)
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
