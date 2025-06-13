import SwiftUI

struct ThemeSettingsView: View {
    @Bindable var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FormSection(title: "Appearance", helpText: "Choose how GitApp looks") {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 8)
                }

                FormSection(title: "Font Size", helpText: "Font size changes apply to newly rendered views or may require an app restart for full effect.") {
                    HStack {
                        Text("Content Font Size:")
                        Spacer()
                        Text("\(Int(themeManager.contentFontSize)) pt")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Slider(value: $themeManager.contentFontSize, in: 10...24, step: 1) {
                        Text("Font Size")
                    } minimumValueLabel: {
                        Text("10")
                    } maximumValueLabel: {
                        Text("24")
                    }
                    .padding(.vertical, 4)
                }

                FormSection(title: "Preview", showDivider: false) {
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sample text with current theme settings.")
                                .font(.system(size: CGFloat(themeManager.contentFontSize)))
                            Text("Another sample line to see the font size.")
                                .font(.system(size: CGFloat(themeManager.contentFontSize)))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 600)
        }
        .navigationTitle("Appearance")
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
