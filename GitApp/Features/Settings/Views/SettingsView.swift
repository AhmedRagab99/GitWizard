import SwiftUI

// Assuming AccountManager, ThemeManager, RepositoryViewModel, AccountsListView
// are all part of the same target and thus accessible without explicit module imports.
// If they were in separate modules, you'd import those modules here.

struct SettingsView: View {
    // Provided via .environmentObject() or direct initialization from GitAppApp
    @Bindable var accountManager: AccountManager
    @Bindable var themeManager: ThemeManager

    // This might need to be an @EnvironmentObject too if it's shared globally
    // or passed down from a common ancestor like GitAppApp.
    // If it's specific to settings or a sub-flow initiated here, @ObservedObject or @StateObject might be appropriate.
    // For now, assuming it's passed in or available in the environment.
    @Bindable var repoViewModel: RepositoryViewModel

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AccountSettingsHostView(accountManager: accountManager, repoViewModel: repoViewModel)) {
                    Label("Accounts", systemImage: "person.crop.circle.fill")
                }
                NavigationLink(destination: ThemeSettingsView(themeManager: themeManager)) {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                NavigationLink(destination: AboutSettingsView(themeManager: themeManager)) {
                    Label("About", systemImage: "info.circle.fill")
                }
            }
            .listStyle(SidebarListStyle()) // More appropriate for macOS settings
            .navigationTitle("Settings")
//            .frame(minWidth: 220, idealWidth: 250) // Adjusted for a typical sidebar width

            // Default view when no selection is made in the sidebar
            VStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                    .padding()
                Text("Select a settings category from the sidebar.")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Wrapper view for AccountsListView to ensure it fits well into the Settings navigation
// and to keep SettingsView cleaner.
struct AccountSettingsHostView: View {
    @Bindable var accountManager: AccountManager
    @Bindable var repoViewModel: RepositoryViewModel

    var body: some View {
        AccountsListView(accountManager: accountManager, repoViewModel: repoViewModel)
            .navigationTitle("Accounts") // Title for the detail part when Accounts is selected
    }
}


struct AboutSettingsView: View {
    @Bindable var themeManager: ThemeManager // Access theme for consistent styling

    var body: some View {
        VStack(spacing: 15) {
            Image("GitAppIcon") // Assuming you have an app icon in your assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 3)
                .padding(.top, 20)

            Text("GitApp")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(appVersion) (Build \(buildNumber))")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Text("Version 1.0.0")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("© \(Calendar.current.component(.year, from: Date())) Your Company Name.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GitApp is a modern Git client designed to streamline your workflow and enhance your productivity.")
                        .font(.body)

                    Text("Built with SwiftUI, leveraging the latest Apple technologies for a seamless experience across platforms.")
                        .font(.callout)
                }
                .padding(5)
            }
            .padding(.horizontal)

            Spacer()

            Text("Powered by Swift & SwiftUI")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
        .navigationTitle("About GitApp")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
