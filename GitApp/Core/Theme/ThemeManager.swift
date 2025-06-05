import SwiftUI
import Observation

@Observable
class ThemeManager {
    var isDarkMode: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isDarkMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
            updateTheme()
        }
    }

    init() {
        // Initialize with system theme by default
        if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
            isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        updateTheme()
    }

    private func updateTheme() {
        guard NSApp != nil, !NSApp.windows.isEmpty else {
            // Defer theme update until NSApp and its windows are available
            // This can be done by observing NSApplication.didFinishLaunchingNotification
            // or by calling updateTheme() at a later point.
            // For now, we'll simply return if NSApp or its windows are not ready.
            return
        }
        if isDarkMode {
            NSApp.appearance = NSAppearance(named: .vibrantDark)
        } else {
            NSApp.appearance = NSAppearance(named: .vibrantLight)
        }
    }
}
