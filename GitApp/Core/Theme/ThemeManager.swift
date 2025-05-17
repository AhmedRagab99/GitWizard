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
        if isDarkMode {
            NSApp.appearance = NSAppearance(named: .vibrantDark)
        } else {
            NSApp.appearance = NSAppearance(named: .vibrantLight)
        }
    }
}
