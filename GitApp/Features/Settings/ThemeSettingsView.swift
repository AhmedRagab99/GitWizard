import SwiftUI

enum ThemeOption: String, CaseIterable {
    case light
    case dark
    case system

    var title: String {
        rawValue.capitalized
    }
}

struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedOption: ThemeOption

    init() {
        let currentTheme = ThemeManager.shared.currentTheme
        if currentTheme.name == "Light" {
            _selectedOption = State(initialValue: .light)
        } else if currentTheme.name == "Dark" {
            _selectedOption = State(initialValue: .dark)
        } else {
            _selectedOption = State(initialValue: .system)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Theme Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)

                Picker("Theme", selection: $selectedOption) {
                    ForEach(ThemeOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedOption) { newOption in
                    switch newOption {
                    case .light:
                        themeManager.setTheme(LightTheme())
                    case .dark:
                        themeManager.setTheme(DarkTheme())
                    case .system:
                        themeManager.setSystemTheme()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardBackgroundColor)
            )

            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        ThemeSettingsView()
            .environmentObject(ThemeManager.shared)
    }
}

