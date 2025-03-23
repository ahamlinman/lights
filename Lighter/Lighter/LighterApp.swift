import LightsKit
import SwiftUI

@main struct LighterApp: App {
	static let baseDir = FileManager.default.homeDirectoryForCurrentUser.appending(
		component: ".lights",
		directoryHint: .isDirectory
	)

	@StateObject var appearanceManager = AppearanceManager(baseDir: baseDir)

	var menuSystemImage: String {
		switch appearanceManager.power {
		case .off: "moon.stars.fill"
		case .on: "sun.max.fill"
		}
	}

	var body: some Scene {
		MenuBarExtra("Lights", systemImage: menuSystemImage) {
			switch appearanceManager.power {
			case .off: Button("Switch to Light Mode") { AppearanceManager.toggleSystemDarkMode() }
			case .on: Button("Switch to Dark Mode") { AppearanceManager.toggleSystemDarkMode() }
			}
			Button("Quit") { NSApp.terminate(nil) }
		}
	}
}

@MainActor class AppearanceManager: ObservableObject {
	@Published var power: Power = effectiveAppearancePower() { didSet { reconcileLightswitch() } }

	private let lightswitch: Lightswitch
	private var observer: NSKeyValueObservation?

	init(baseDir: URL) {
		lightswitch = Lightswitch(baseDir: baseDir)
		observer = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
			Task { @MainActor [weak self] in
				self?.power = AppearanceManager.effectiveAppearancePower()
			}
		}
		reconcileLightswitch()
	}

	deinit { observer?.invalidate() }

	func reconcileLightswitch() { do { try lightswitch.flip(power) } catch {} }

	static func toggleSystemDarkMode() {
		let script = """
			tell application "System Events"
				tell appearance preferences
					set dark mode to not dark mode
				end tell
			end tell
			"""

		let scriptObject = NSAppleScript(source: script)!
		var error: NSDictionary?
		scriptObject.executeAndReturnError(&error)
	}

	private static func effectiveAppearancePower() -> Power {
		if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
			.off
		} else {
			.on
		}
	}
}
