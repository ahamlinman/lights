import SwiftUI

@main struct LighterApp: App {
	@StateObject var appearanceManager = AppearanceManager()

	var menuSystemImage: String { appearanceManager.isDark ? "moon.stars.fill" : "sun.max.fill" }

	var body: some Scene {
		MenuBarExtra("Lights", systemImage: menuSystemImage) {
			if appearanceManager.isDark {
				Button("Switch to Light Mode") { AppearanceManager.toggleSystemDarkMode() }
			} else {
				Button("Switch to Dark Mode") { AppearanceManager.toggleSystemDarkMode() }
			}
			Button("Quit") { NSApp.terminate(nil) }
		}
	}
}

@MainActor class AppearanceManager: ObservableObject {
	@Published var isDark: Bool = isEffectiveAppearanceDark()

	private var observer: NSKeyValueObservation?

	init() {
		observer = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
			DispatchQueue.main.async { [weak self] in
				self?.isDark = AppearanceManager.isEffectiveAppearanceDark()
			}
		}
	}

	deinit { observer?.invalidate() }

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
		print(error as Any)
	}

	private static func isEffectiveAppearanceDark() -> Bool {
		NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
	}
}
