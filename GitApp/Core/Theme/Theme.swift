import SwiftUI

// MARK: - Theme Protocol
protocol Theme: Hashable {
    var name: String { get }
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var accentColor: Color { get }
    var cardBackgroundColor: Color { get }
    var isDark: Bool { get }
}

// MARK: - Light Theme
struct LightTheme: Theme {
    let name = "Light"
    let primaryColor = Color(red: 0, green: 0.478, blue: 1)
    let secondaryColor = Color(red: 0.352, green: 0.784, blue: 0.98)
    let backgroundColor = Color(red: 0.949, green: 0.949, blue: 0.969)
    let textColor = Color(red: 0, green: 0, blue: 0)
    let accentColor = Color(red: 1, green: 0.584, blue: 0)
    let cardBackgroundColor = Color(red: 1, green: 1, blue: 1)
    let isDark = false
}

// MARK: - Dark Theme
struct DarkTheme: Theme {
    let name = "Dark"
    let primaryColor = Color(red: 0.039, green: 0.518, blue: 1)
    let secondaryColor = Color(red: 0.352, green: 0.784, blue: 0.98)
    let backgroundColor = Color(red: 0, green: 0, blue: 0)
    let textColor = Color(red: 1, green: 1, blue: 1)
    let accentColor = Color(red: 1, green: 0.624, blue: 0.039)
    let cardBackgroundColor = Color(red: 0.11, green: 0.11, blue: 0.118)
    let isDark = true
}

// MARK: - Custom Theme
struct CustomTheme: Theme {
    let name: String
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    let cardBackgroundColor: Color
    let isDark: Bool

    init(
        name: String,
        primaryColor: Color,
        secondaryColor: Color,
        backgroundColor: Color,
        textColor: Color,
        accentColor: Color,
        cardBackgroundColor: Color
    ) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.cardBackgroundColor = cardBackgroundColor
        self.isDark = !backgroundColor.isLight
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published  var currentTheme: any Theme
    @Published  var isDarkMode: Bool

    private init() {
        // Load saved theme or use system theme
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        let systemIsDark = ColorScheme.dark == .dark

        if let savedTheme = savedTheme {
            switch savedTheme {
            case "Light":
                currentTheme = LightTheme()
                isDarkMode = false
            case "Dark":
                currentTheme = DarkTheme()
                isDarkMode = true
            default:
                currentTheme = systemIsDark ? DarkTheme() : LightTheme()
                isDarkMode = systemIsDark
            }
        } else {
            currentTheme = systemIsDark ? DarkTheme() : LightTheme()
            isDarkMode = systemIsDark
        }
    }

    func setTheme(_ theme: any Theme) {
        currentTheme = theme
        isDarkMode = theme.isDark
        UserDefaults.standard.set(theme.name, forKey: "selectedTheme")
    }

    func setSystemTheme() {
        let systemIsDark = ColorScheme.dark == .dark
        currentTheme = systemIsDark ? DarkTheme() : LightTheme()
        isDarkMode = systemIsDark
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
    }
}

// MARK: - Color Extension
extension Color {
    var isLight: Bool {
        let components = self.components
        let brightness = ((components.red * 299) + (components.green * 587) + (components.blue * 114)) / 1000
        return brightness > 0.5
    }

    private var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        if let cgColor = self.cgColor {
            let components = cgColor.components
            switch components?.count {
            case 2: // Grayscale
                r = components?[0] ?? 0
                g = components?[0] ?? 0
                b = components?[0] ?? 0
                o = components?[1] ?? 0
            case 4: // RGBA
                r = components?[0] ?? 0
                g = components?[1] ?? 0
                b = components?[2] ?? 0
                o = components?[3] ?? 0
            default:
                break
            }
        }

        return (r, g, b, o)
    }
}

// MARK: - View Modifiers
struct ThemedBackground: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .background(themeManager.currentTheme.backgroundColor)
    }
}

struct ThemedText: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .foregroundColor(themeManager.currentTheme.textColor)
    }
}

struct ThemedCard: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .background(themeManager.currentTheme.cardBackgroundColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }

    func themedText() -> some View {
        modifier(ThemedText())
    }

    func themedCard() -> some View {
        modifier(ThemedCard())
    }
}
