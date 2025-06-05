import SwiftUI

struct ThemeSettingsView: View {
    @Bindable var themeManager: ThemeManager

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $themeManager.currentTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }

            Section(header: Text("Font Size")) {
                Stepper("Content Font Size: \(Int(themeManager.contentFontSize)) pt", value: $themeManager.contentFontSize, in: 10...24, step: 1)
                Text("Font size changes apply to newly rendered views or may require an app restart for full effect.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Preview")) {
                Text("Sample text with current theme settings.")
                    .font(.system(size: CGFloat(themeManager.contentFontSize)))
                Text("Another sample line to see the font size.")
                    .font(.system(size: CGFloat(themeManager.contentFontSize)))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Appearance")
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#if DEBUG
struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let previewThemeManager = ThemeManager()
        ThemeSettingsView(themeManager: previewThemeManager)
            .frame(width: 450, height: 400)
    }
}
#endif
