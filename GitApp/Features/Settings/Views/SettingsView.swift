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

    @State private var selectedSetting: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 4) {
                // Settings navigation list
                VStack(spacing: 0) {
                    SettingsNavigationRow(
                        label: "Accounts",
                        icon: "person.crop.circle.fill",
                        isSelected: selectedSetting == "accounts",
                        action: { selectedSetting = "accounts" }
                    )

                    SettingsNavigationRow(
                        label: "Appearance",
                        icon: "paintbrush.fill",
                        isSelected: selectedSetting == "appearance",
                        action: { selectedSetting = "appearance" }
                    )

                    SettingsNavigationRow(
                        label: "About",
                        icon: "info.circle.fill",
                        isSelected: selectedSetting == "about",
                        action: { selectedSetting = "about" }
                    )
                }
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)

                Spacer()
            }
            .frame(minWidth: 220, idealWidth: 250)
            .padding(.top)
            .navigationTitle("Settings")
            .background(Color(.windowBackgroundColor))

            // Content view based on selection
            Group {
                if selectedSetting == "accounts" {
                    AccountSettingsHostView(accountManager: accountManager, repoViewModel: repoViewModel)
                } else if selectedSetting == "appearance" {
                    ThemeSettingsView(themeManager: themeManager)
                } else if selectedSetting == "about" {
                    AboutSettingsView(themeManager: themeManager)
                } else {
                    // Default view when no selection is made
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
    }
}

// Custom settings navigation row component
struct SettingsNavigationRow: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ListRow(
            isSelected: isSelected,
            padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
            onTap: action
        ) {
            Label(label, systemImage: icon)
                .font(.body)
                .foregroundColor(isSelected ? .primary : .secondary)
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
        ScrollView {
            VStack(spacing: 24) {
                // App icon and version info
                Card {
                    VStack(spacing: 15) {
                        Image("GitAppIcon") // Assuming you have an app icon in your assets
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                            .padding(.top, 10)

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
                    }
                }

                // App description
                FormSection(title: "About GitApp") {
                    Text("GitApp is a modern Git client designed to streamline your workflow and enhance your productivity.")
                        .font(.body)
                        .padding(.vertical, 4)

                    Text("Built with SwiftUI, leveraging the latest Apple technologies for a seamless experience across platforms.")
                        .font(.callout)
                        .padding(.vertical, 4)
                }

                // Copyright info
                FormSection(title: "Legal", showDivider: false) {
                    Text("© \(Calendar.current.component(.year, from: Date())) Your Company Name.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)

                    Text("Powered by Swift & SwiftUI")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(maxWidth: 600)
        }
        .navigationTitle("About GitApp")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
