import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button {
                    themeManager.setTheme(theme)
                } label: {
                    HStack {
                        Text(theme.rawValue.capitalized)
                        Spacer()
                        if themeManager.currentTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Appearance")
    }
}

#Preview {
    NavigationView {
        ThemeSettingsView()
    }
}
