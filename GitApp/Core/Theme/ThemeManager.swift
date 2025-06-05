import SwiftUI
import Observation

enum Theme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { self.rawValue }
}

@Observable
class ThemeManager {
    var currentTheme: Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "currentTheme")
            applyTheme()
        }
    }

    var contentFontSize: Double {
        didSet {
            UserDefaults.standard.set(contentFontSize, forKey: "contentFontSize")
            // Notification/mechanism for views to update if needed could be added here
        }
    }

    var isDarkMode: Bool {
        get {
            switch currentTheme {
            case .light:
                return false
            case .dark:
                return true
            case .system:
                // When system, reflect the actual current system state
                return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            }
        }
        set {
            // When isDarkMode is set, adjust currentTheme accordingly
            if newValue {
                // If trying to set to dark mode, and system is light, choose explicit Dark theme.
                // If system is already dark, setting to System theme is also fine.
                currentTheme = .dark
            } else {
                // If trying to set to light mode, and system is dark, choose explicit Light theme.
                // If system is already light, setting to System theme is also fine.
                currentTheme = .light
            }
            // The didSet of currentTheme will call applyTheme()
        }
    }

    init() {
        let savedThemeName = UserDefaults.standard.string(forKey: "currentTheme")
        self.currentTheme = Theme(rawValue: savedThemeName ?? Theme.system.rawValue) ?? .system

        self.contentFontSize = UserDefaults.standard.double(forKey: "contentFontSize")
        if self.contentFontSize == 0 { // If not set, provide a default
            self.contentFontSize = 14 // Default font size, adjust as needed for your app
        }
        applyTheme() // Apply initial theme
    }

    func applyTheme() {
        guard let application = NSApp else { return }

        switch currentTheme {
        case .system:
            application.appearance = nil // Let the system control the appearance
        case .light:
            application.appearance = NSAppearance(named: .vibrantLight)
        case .dark:
            application.appearance = NSAppearance(named: .vibrantDark)
        }

        // For contentFontSize, views should observe ThemeManager directly.
        // If a more global notification is needed for font size (e.g., for UIKit parts), that would be separate.
    }
}
