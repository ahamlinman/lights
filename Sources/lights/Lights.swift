import Foundation

enum Power: String {
	case off = "off"
	case on = "on"
}

enum LightsError: Error, CustomStringConvertible {
	case badCurrentLink(target: URL)
	case someHooksNotInvoked

	var description: String {
		switch self {
		case let .badCurrentLink(target):
			"The current lights link points to \(target.absoluteString), not a lights config directory."
		case .someHooksNotInvoked:
			"Failed to invoke some hooks."
		}
	}
}

struct Lights {
	let baseDir: URL

	var offDir: URL {
		baseDir.appending(
			component: "off",
			directoryHint: .isDirectory)
	}
	var onDir: URL {
		baseDir.appending(
			component: "on",
			directoryHint: .isDirectory)
	}
	var hooksDir: URL {
		baseDir.appending(
			component: "hooks",
			directoryHint: .isDirectory)
	}
	var currentLink: URL {
		baseDir.appending(
			component: "current",
			directoryHint: .notDirectory)
	}

	init(baseDir: URL) throws {
		self.baseDir = baseDir

		for dir in [self.baseDir, self.offDir, self.onDir, self.hooksDir] {
			try FileManager.default.createDirectory(
				at: dir,
				withIntermediateDirectories: true)
		}

		do {
			try FileManager.default.createSymbolicLink(
				at: self.currentLink,
				withDestinationURL: self.offDir)
		} catch let error as NSError
			where error.domain == NSCocoaErrorDomain
			&& error.code == NSFileWriteFileExistsError
		{}
	}

	func power() throws -> Power {
		let target = self.currentLink.resolvingSymlinksInPath()
		if let power = Power(rawValue: target.lastPathComponent) {
			return power
		} else {
			throw LightsError.badCurrentLink(target: target)
		}
	}

	func flip(_ power: Power) throws {
		let linkDestination =
			switch power {
			case .off: self.offDir
			case .on: self.onDir
			}
		try switchCurrentLink(toNewTarget: linkDestination)
		try runAllHooks()
	}

	private func switchCurrentLink(toNewTarget destination: URL) throws {
		let linkReplacementDir = try FileManager.default.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: self.currentLink,
			create: true)
		defer {
			try? FileManager.default.removeItem(at: linkReplacementDir)
		}

		let newCurrentLink = linkReplacementDir.appending(
			component: "lights-current",
			directoryHint: .notDirectory)
		try FileManager.default.createSymbolicLink(
			at: newCurrentLink,
			withDestinationURL: destination)

		// I can't get replaceItem[At] to do what I want here.
		// They both complain that ~/.lights/current doesn't exist.
		let result = rename(
			newCurrentLink.relativePath,
			self.currentLink.relativePath)
		if result != 0 {
			throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
		}
	}

	private func runAllHooks() throws {
		var anyHookNotInvoked = false
		for hookURL in try FileManager.default.contentsOfDirectory(
			at: self.hooksDir, includingPropertiesForKeys: nil)
		{
			do {
				try Process.run(hookURL, arguments: [])  // TODO: Output to /dev/null?
			} catch let err {
				fputs("Hook Not Invoked: \(err.localizedDescription)\n", stderr)
				anyHookNotInvoked = true
			}
		}
		if anyHookNotInvoked {
			throw LightsError.someHooksNotInvoked
		}
	}
}
