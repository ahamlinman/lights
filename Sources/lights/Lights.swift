// See https://github.com/swiftlang/swift/issues/77866.
// Note that we must import this first to override Foundation's import.
// swift-format-ignore: OrderedImports
#if canImport(Glibc)
	@preconcurrency import Glibc
#endif

import Foundation

enum Power: String { case off, on }

enum LightsError: Error, CustomStringConvertible {
	case someHooksNotInvoked
	case badCurrentLink(target: URL)

	var description: String {
		switch self {
		case .someHooksNotInvoked: "Failed to invoke some hooks."
		case .badCurrentLink(let target):
			"The current lights link points to \(target.absoluteString), not a lights config directory."
		}
	}
}

struct Lights {
	let baseDir: URL

	var offDir: URL { baseDir.appending(component: "off", directoryHint: .isDirectory) }
	var onDir: URL { baseDir.appending(component: "on", directoryHint: .isDirectory) }
	var hooksDir: URL { baseDir.appending(component: "hooks", directoryHint: .isDirectory) }
	var currentLink: URL { baseDir.appending(component: "current", directoryHint: .notDirectory) }

	init(baseDir: URL) throws {
		self.baseDir = baseDir

		for dir in [baseDir, offDir, onDir, hooksDir] {
			try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
		}

		do {
			try FileManager.default.createSymbolicLink(at: currentLink, withDestinationURL: offDir)
		} catch CocoaError.fileWriteFileExists {}
	}

	func power() throws -> Power {
		let target = currentLink.resolvingSymlinksInPath()
		if let power = Power(rawValue: target.lastPathComponent) {
			return power
		} else {
			throw LightsError.badCurrentLink(target: target)
		}
	}

	func flip(_ power: Power) throws {
		let linkDestination =
			switch power {
			case .off: offDir
			case .on: onDir
			}
		try switchCurrentLink(toNewTarget: linkDestination)
		try runAllHooks()
	}

	private func switchCurrentLink(toNewTarget destination: URL) throws {
		let linkReplacementDir = try FileManager.default.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: currentLink,
			create: true
		)
		defer { try? FileManager.default.removeItem(at: linkReplacementDir) }

		let newCurrentLink = linkReplacementDir.appending(
			component: "lights-current",
			directoryHint: .notDirectory
		)
		try FileManager.default.createSymbolicLink(
			at: newCurrentLink,
			withDestinationURL: destination
		)

		// I can't get replaceItem[At] to do what I want here.
		// They both complain that ~/.lights/current doesn't exist.
		let result = rename(newCurrentLink.relativePath, currentLink.relativePath)
		if result != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
	}

	private func runAllHooks() throws {
		var anyHookNotInvoked = false
		for hookURL in try FileManager.default.contentsOfDirectory(
			at: hooksDir,
			includingPropertiesForKeys: nil
		) {
			do {
				let _ = try Process.run(hookURL, arguments: [])  // TODO: Output to /dev/null?
			} catch {
				anyHookNotInvoked = true
				fputs("Hook Not Invoked: \(error.localizedDescription)\n", stderr)
			}
		}
		if anyHookNotInvoked { throw LightsError.someHooksNotInvoked }
	}
}
