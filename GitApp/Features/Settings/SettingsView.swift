import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintpalette")
                        .themedText()
                }
            }
            .navigationTitle("Settings")
            .themedBackground()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
}
