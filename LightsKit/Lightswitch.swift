import Foundation

public enum Power: String { case off, on }

public struct Lightswitch {
	let baseDir: URL

	private var offDir: URL { baseDir.appending(component: "off", directoryHint: .isDirectory) }
	private var onDir: URL { baseDir.appending(component: "on", directoryHint: .isDirectory) }
	private var hooksDir: URL { baseDir.appending(component: "hooks", directoryHint: .isDirectory) }
	private var currentLink: URL {
		baseDir.appending(component: "current", directoryHint: .notDirectory)
	}

	public var power: Power? {
		Power(rawValue: currentLink.resolvingSymlinksInPath().lastPathComponent)
	}

	public init(baseDir: URL) { self.baseDir = baseDir }

	public func flip(_ power: Power) throws {
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
	}

	private func switchCurrentLink(toNewTarget destination: URL) throws {
		let linkReplacementDir = try FileManager.default.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: currentLink,
			create: true
		)
		defer {
			try? FileManager.default.removeItem(at: linkReplacementDir)
		}

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
		if result != 0 {
			throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
		}
	}

	private func runAllHooks() throws {
		var failures: [FailedLightsHook] = []
		for hookURL in try FileManager.default.contentsOfDirectory(
			at: hooksDir,
			includingPropertiesForKeys: nil
		) {
			do {
				let process = Process()
				process.executableURL = hookURL
				process.standardInput = FileHandle.nullDevice
				process.standardOutput = FileHandle.nullDevice
				process.standardError = FileHandle.nullDevice
				try process.run()
			} catch {
				failures.append(FailedLightsHook(hookURL: hookURL, error: error))
			}
		}
		if !failures.isEmpty {
			throw LightsHookInvocationError(failures: failures)
		}
	}
}

public struct FailedLightsHook: Sendable {
	public let hookURL: URL
	public let error: any Error
}

public struct LightsHookInvocationError: Error, CustomStringConvertible {
	public let failures: [FailedLightsHook]

	public var description: String {
		"Failed to invoke some hooks.\n"
			+ failures.map { failure in
				"\t\(failure.hookURL.lastPathComponent): \(failure.error.localizedDescription)"
			}
			.joined(separator: "\n")
	}
}
