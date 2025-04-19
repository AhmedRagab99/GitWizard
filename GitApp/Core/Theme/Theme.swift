import SwiftUI

// MARK: - Theme Types
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var currentTheme: AppTheme
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let savedTheme = userDefaults.string(forKey: "appTheme")
        self.currentTheme = AppTheme(rawValue: savedTheme ?? "system") ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: "appTheme")
    }

    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}

// MARK: - Theme Environment
private struct ThemeKey: EnvironmentKey {
    @MainActor
    static var defaultValue: ThemeManager {
        ThemeManager()
    }
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func themeManager(_ manager: ThemeManager) -> some View {
        environment(\.themeManager, manager)
    }
}
