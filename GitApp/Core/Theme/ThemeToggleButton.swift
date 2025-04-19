import SwiftUI

struct ThemeToggleButton: View {
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Menu {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button {
                    themeManager.setTheme(theme)
                } label: {
                    HStack {
                        Text(theme.rawValue.capitalized)
                        if themeManager.currentTheme == theme {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: themeManager.currentTheme == .dark ? "moon.fill" :
                  themeManager.currentTheme == .light ? "sun.max.fill" : "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ThemeToggleButton()
        .padding()
}
