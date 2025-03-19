import Foundation

enum Power: String { case off, on }

struct Lights {
	let baseDir: URL

	private var offDir: URL { baseDir.appending(component: "off", directoryHint: .isDirectory) }
	private var onDir: URL { baseDir.appending(component: "on", directoryHint: .isDirectory) }
	private var hooksDir: URL { baseDir.appending(component: "hooks", directoryHint: .isDirectory) }
	private var currentLink: URL {
		baseDir.appending(component: "current", directoryHint: .notDirectory)
	}

	var power: Power? { Power(rawValue: currentLink.resolvingSymlinksInPath().lastPathComponent) }

	func flip(_ power: Power) throws {
		let linkDestination =
			switch power {
			case .off: offDir
			case .on: onDir
			}
		try ensureConfigTreeExists()
		try switchCurrentLink(toNewTarget: linkDestination)
		try runAllHooks()
	}

	private func ensureConfigTreeExists() throws {
		for dir in [baseDir, offDir, onDir, hooksDir] {
			try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
		}
		do {
			try FileManager.default.createSymbolicLink(at: currentLink, withDestinationURL: offDir)
		} catch CocoaError.fileWriteFileExists {}
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
		if anyHookNotInvoked { throw HookInvocationError() }

		struct HookInvocationError: Error, CustomStringConvertible {
			let description = "Failed to invoke some hooks."
		}
	}
}
