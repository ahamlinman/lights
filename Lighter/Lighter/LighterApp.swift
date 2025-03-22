import LightsKit
import SwiftUI

@main struct LighterApp: App {
	static let baseDir = FileManager.default.homeDirectoryForCurrentUser.appending(
		component: ".lights",
		directoryHint: .isDirectory
	)

	@StateObject var appearanceManager = AppearanceManager(baseDir: baseDir)

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
	@Published var isDark: Bool = isEffectiveAppearanceDark() { didSet { reconcileLightswitch() } }

	private let lightswitch: Lightswitch
	private var observer: NSKeyValueObservation?

	init(baseDir: URL) {
		lightswitch = Lightswitch(baseDir: baseDir)
		observer = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
			DispatchQueue.main.async { [weak self] in
				self?.isDark = AppearanceManager.isEffectiveAppearanceDark()
			}
		}
		reconcileLightswitch()
	}

	deinit { observer?.invalidate() }

	func reconcileLightswitch() {
		do { try lightswitch.flip(isDark ? .off : .on) } catch { print(error) }
	}

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

	private static func isEffectiveAppearanceDark() -> Bool {
		NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
	}
}
