import SwiftUI

struct AccountsListView: View {
     var accountManager: AccountManager
    var repoViewModel : RepositoryViewModel // Add view model
    @State private var showingAddAccountSheet = false
    @State private var selectedAccountID: Account.ID? // For selection in the list
    @State private var accountToEdit: Account? // For showing update token sheet
    @State private var showDeleteConfirmation = false
    @State private var accountToDelete: Account? = nil

    // For displaying repositories
    @State private var repositories: [GitHubRepository] = []
    @State private var isLoadingRepos: Bool = false
    @State private var repoFetchError: String? = nil

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigation) { // Example: For a potential sidebar toggle
                Button(action: { NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil) }) {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Sidebar")
            }
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            AddAccountView(accountManager: accountManager)
        }
        .sheet(item: $accountToEdit) { account in // Using .sheet(item:...) for editing
            UpdateTokenView(account: account, accountManager: accountManager)
        }
        .confirmationDialog(
            "Delete Account \"\(accountToDelete?.username ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            presenting: accountToDelete
        ) { acc in
            Button("Delete Account", role: .destructive) {
                accountManager.deleteAccount(accountID: acc.id)
                if selectedAccountID == acc.id {
                    selectedAccountID = nil // Deselect if the deleted account was selected
                    repositories = [] // Clear repositories view
                }
                accountToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                accountToDelete = nil
            }
        } message: { acc in
            Text("Are you sure you want to delete the account for \(acc.username)? This action cannot be undone.")
        }
        .frame(minWidth: 600, minHeight: 400) // Give the window a reasonable default size
        .onChange(of: selectedAccountID) { _, newSelectedID in
            repositories = [] // Clear old repos
            repoFetchError = nil
            if let newSelectedID = newSelectedID,
               let account = accountManager.accounts.first(where: { $0.id == newSelectedID }) {
                fetchRepos(for: account)
            }
        }
        .onAppear {
            // If an account is already selected on appear (e.g. from previous state)
            if let currentSelectedID = selectedAccountID,
               let account = accountManager.accounts.first(where: { $0.id == currentSelectedID }) {
                fetchRepos(for: account)
            } else if let firstAccount = accountManager.accounts.first {
                // Or select the first account if none are selected
                selectedAccountID = firstAccount.id
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $selectedAccountID) {
                if accountManager.accounts.isEmpty {
                    Text("No accounts added yet.")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.controlBackgroundColor))
                } else {
                    ForEach(accountManager.accounts) { account in
                        AccountRow(account: account, selectedAccountID: $selectedAccountID)
                            .tag(account.id)
                    }
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 220, idealWidth: 250, maxWidth: 300)
            .background(Color(.controlBackgroundColor))

            Divider()

            HStack {
                Button {
                    showingAddAccountSheet = true
                } label: {
                    Label("Add Account", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .padding([.leading, .bottom, .top], 8)

                Spacer()

                Button {
                    if let selectedID = selectedAccountID,
                       let account = accountManager.accounts.first(where: { $0.id == selectedID }) {
                        accountToDelete = account
                        showDeleteConfirmation = true
                    }
                } label: {
                    Label("Remove Account", systemImage: "minus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(selectedAccountID == nil)
                .padding([.trailing, .bottom, .top], 8)
                .help("Remove selected account")
            }
            .background(Material.bar)
        }
        .background(Color(.controlBackgroundColor))
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedID = selectedAccountID,
           let account = accountManager.accounts.first(where: { $0.id == selectedID }) {
            AccountDetailView(
                account: account,
                accountManager: accountManager,
                repoViewModel:repoViewModel,
                repositories: $repositories,
                isLoadingRepos: $isLoadingRepos,
                repoFetchError: $repoFetchError,
                onUpdateToken: { acc in self.accountToEdit = acc }
            )
        } else {
            VStack {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 50))
                    .padding()
                Text("Select an account to see details or add a new account.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fetchRepos(for account: Account) {
        isLoadingRepos = true
        repoFetchError = nil
        Task {
            do {
                let fetchedRepos = try await accountManager.fetchRepositories(for: account)
                self.repositories = fetchedRepos
            } catch {
                self.repoFetchError = error.localizedDescription
                self.repositories = [] // Clear on error
            }
            isLoadingRepos = false
        }
    }
}

struct AccountRow: View {
    let account: Account
    @Binding var selectedAccountID: Account.ID? // Added binding

    var isSelected: Bool { // Computed property for selection state
        account.id == selectedAccountID
    }

    var body: some View {
        HStack(spacing: 10) { // Adjusted spacing
            if let avatarURLString = account.avatarURL, let avatarURL = URL(string: avatarURLString) {
                AsyncImage(url: avatarURL) {
                    image in image.resizable()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 3) { // Adjusted spacing
                Text(account.username).font(.headline).lineLimit(1)
                Text(account.type.rawValue).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                if account.type == .githubEnterprise, let server = account.serverURL {
                    Text(URL(string: server)?.host ?? "Enterprise")
                        .font(.caption2) // Made smaller
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            Spacer() // Ensure content pushes to leading edge
        }
        .padding(.vertical, 6) // Adjusted padding
        .padding(.horizontal, 8)
        // Use the computed isSelected property
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

struct AccountDetailView: View {
    let account: Account
    var accountManager: AccountManager
    var repoViewModel : RepositoryViewModel // Add view model
    @Binding var repositories: [GitHubRepository] // User's direct repositories
    @Binding var isLoadingRepos: Bool // For user's direct repositories
    @Binding var repoFetchError: String? // For user's direct repositories
    var onUpdateToken: (Account) -> Void

    @State private var userDetails: GitHubUser? = nil
    @State private var isLoadingUserDetails: Bool = false

    // New state for organizations
    @State private var organizations: [GitHubOrganization] = []
    @State private var isLoadingOrganizations: Bool = false
    @State private var organizationFetchError: String? = nil

    // New state for repositories of a selected organization
    @State private var selectedOrganization: GitHubOrganization? = nil
    @State private var organizationRepositories: [GitHubRepository] = []
    @State private var isLoadingOrgRepos: Bool = false
    @State private var orgRepoFetchError: String? = nil

    @State private var currentDetailTab: DetailTab = .accountDetails
    @State private var selectedRepository: GitHubRepository? = nil // To hold the selected repo

    enum DetailTab {
        case accountDetails, repositories
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                if let avatarURLString = userDetails?.avatarUrl ?? account.avatarURL, let avatarURL = URL(string: avatarURLString) {
                    AsyncImage(url: avatarURL) {
                        image in image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .padding(.top, 4)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .padding(.top, 4)
                }

                VStack(alignment: .leading) {
                    Text(userDetails?.name ?? account.username).font(.title).fontWeight(.bold)
                    Text("@\(account.username)").font(.title3).foregroundColor(.secondary)
                    if let profileURL = account.webURL {
                        Link("View on GitHub", destination: profileURL)
                    }
                }
                Spacer()
            }
            .padding(.bottom)

            Picker("Detail View", selection: $currentDetailTab) {
                Text("Account").tag(DetailTab.accountDetails)
                Text("Repositories").tag(DetailTab.repositories)
            }
            .pickerStyle(.segmented)
            .padding(.bottom)

            if currentDetailTab == .accountDetails {
                accountDetailsTab
            } else {
                repositoriesAndOrgsTab // Renamed from repositoriesTab
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.textBackgroundColor)) // Use a suitable background
        .onAppear {
            fetchInitialData()
        }
        .onChange(of: account) { _, newAccount in
             fetchInitialData(for: newAccount)
        }
    }

    private func fetchInitialData(for acc: Account? = nil) {
        let targetAccount = acc ?? account
        fetchUserDetails(for: targetAccount)
        // Repositories for the user are typically fetched by the parent view (AccountsListView)
        // and passed via binding. If not, uncomment and adapt:
        // fetchUserRepositories(for: targetAccount)
        fetchOrganizations(for: targetAccount)
    }

    private func fetchUserDetails(for accountToFetch: Account) {
        isLoadingUserDetails = true
        Task {
            do {
                self.userDetails = try await accountManager.fetchUserDetails(for: accountToFetch)
            } catch {
                // Handle error appropriately
                print("Error fetching user details: \(error)")
            }
            isLoadingUserDetails = false
        }
    }

    private func fetchOrganizations(for accountToFetch: Account) {
        isLoadingOrganizations = true
        organizationFetchError = nil
        Task {
            do {
                self.organizations = try await accountManager.fetchOrganizations(for: accountToFetch)
            } catch {
                self.organizationFetchError = error.localizedDescription
            }
            isLoadingOrganizations = false
        }
    }

    private func fetchUserRepositories(for accountToFetch: Account) {
        // This is already handled by the parent view, passed via @Binding repositories
        // If you want this view to also trigger it, you can call the parent's fetch function
        // or duplicate the logic here, ensuring isLoadingRepos and repoFetchError are updated.
        // For now, we rely on the parent binding.
    }

    private func fetchRepos(for org: GitHubOrganization, accountToFetch: Account) {
        selectedOrganization = org
        isLoadingOrgRepos = true
        orgRepoFetchError = nil
        organizationRepositories = [] // Clear previous org's repos
        Task {
            do {
                let fetchedRepos = try await accountManager.fetchRepositories(for: accountToFetch, organizationLogin: org.login)
                self.organizationRepositories = fetchedRepos
            } catch {
                self.orgRepoFetchError = error.localizedDescription
            }
            isLoadingOrgRepos = false
        }
    }

    @ViewBuilder
    var accountDetailsTab: some View {
        Form {
            Section(header: Text("Account Information")) {
                LabeledContent("Username", value: account.username)
                LabeledContent("Type", value: account.type.rawValue)
                if account.type == .githubEnterprise, let serverURL = account.serverURL {
                    LabeledContent("Server", value: serverURL)
                }
                if let email = userDetails?.email {
                    LabeledContent("Email", value: email)
                }
                if let company = userDetails?.company {
                    LabeledContent("Company", value: company)
                }
                if let location = userDetails?.location {
                    LabeledContent("Location", value: location)
                }
                LabeledContent("Status") {
                    Text("Online").foregroundColor(.green) // Placeholder
                }
            }

            Section {
                Button("Update Token...") {
                    onUpdateToken(account)
                }
            }
        }
        .formStyle(.grouped)
        .overlay {
            if isLoadingUserDetails {
                VStack {
                    ProgressView("Loading Account Details...")
                    Spacer()
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    var repositoriesAndOrgsTab: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section("Your Repositories") {
                    if isLoadingRepos {
                        ProgressView().padding()
                    } else if let error = repoFetchError {
                        Text("Error: \(error)").foregroundColor(.red).padding()
                    } else if repositories.isEmpty {
                        Text("No repositories found.").padding()
                    } else {
                        ForEach(repositories) { repo in
                            RepositoryListRow(repository: repo,
                                              isSelected: selectedRepository?.id == repo.id,
                                              showOwner: false,
                                              repoViewModel: repoViewModel)
                            .contentShape(Rectangle()) // Make the whole row tappable
                            .onTapGesture {
                                selectedRepository = repo
                                // Potentially scroll to a detail view or update a detail section
                            }
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)

                Section("Organizations") {
                    if isLoadingOrganizations {
                        ProgressView().padding()
                    } else if let error = organizationFetchError {
                        Text("Error: \(error)").foregroundColor(.red).padding()
                    } else if organizations.isEmpty {
                        Text("No organizations found or you are not a member of any.").padding()
                    } else {
                        ForEach(organizations) { org in
                            DisclosureGroup(
                                isExpanded: .init( // Two-way binding for expansion state
                                    get: { selectedOrganization?.id == org.id },
                                    set: { isExpanding in
                                        if isExpanding {
                                            fetchRepos(for: org, accountToFetch: account)
                                        } else {
                                            if selectedOrganization?.id == org.id {
                                                selectedOrganization = nil
                                                organizationRepositories = []
                                            }
                                        }
                                    }
                                ),
                                content: { organizationRepositoriesList(for: org) }, // Extracted content
                                label: {
                                    OrganizationRow(organization: org)
                                }
                            )
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(minHeight: 300)
    }

    @ViewBuilder
    private func organizationRepositoriesList(for org: GitHubOrganization) -> some View {
        if selectedOrganization?.id == org.id {
            if isLoadingOrgRepos {
                ProgressView().padding([.leading, .top])
            } else if let error = orgRepoFetchError {
                Text("Error: \(error)").foregroundColor(.red).padding([.leading, .top])
            } else if organizationRepositories.isEmpty {
                Text("No repositories found for \(org.login).")
                    .foregroundColor(.secondary)
                    .padding([.leading, .top])
            } else {
                ForEach(organizationRepositories) { repo in
                    RepositoryListRow(repository: repo,
                                      isSelected: selectedRepository?.id == repo.id,
                                      showOwner: true,
                                      ownerLogin: org.login,
                                      repoViewModel: repoViewModel) // Ensure repoViewModel is passed here
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRepository = repo
                    }
                    .padding(.leading) // Indent org repos
                    Divider().padding(.leading)
                }
            }
        }
    }
}

struct OrganizationRow: View {
    let organization: GitHubOrganization

    var body: some View {
        HStack {
            if let avatarURLString = organization.avatarUrl, let avatarURL = URL(string: avatarURLString) {
                AsyncImage(url: avatarURL) { image in image.resizable() }
                placeholder: { Image(systemName: "person.2.crop.square.stack.fill").resizable() }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "person.2.crop.square.stack.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading) {
                Text(organization.login).font(.headline)
                if let description = organization.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

// Ensure RepositoryListRow (previously RepositoryRow within AccountDetailView) is defined or adapted
// For simplicity, I'm renaming/defining a basic version here.
// You might need to adjust based on your existing RepositoryRow.

struct RepositoryListRow: View {
    let repository: GitHubRepository
    var isSelected: Bool
    var showOwner: Bool = true
    var ownerLogin: String? = nil
    var repoViewModel : RepositoryViewModel
    @State private var showingCloneErrorAlert = false
    @State private var cloneErrorMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: repository.isPrivate ? "lock.fill" : "folder.fill")
                .font(.title3)
                .foregroundColor(repository.isPrivate ? .orange : .accentColor)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .accentColor : .primary)

                if showOwner {
                    Text(ownerLogin ?? repository.owner?.login ?? "Unknown Owner") // Safe unwrap
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let description = repository.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    if let stars = repository.stargazersCount, stars > 0 {
                        Label("\(stars)", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                    if let forks = repository.forksCount, forks > 0 {
                        Label("\(forks)", systemImage: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.8))
                    }
                    if let lang = repository.language, !lang.isEmpty {
                        Label(lang, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(languageColor(lang).opacity(0.8)) // Using the helper
                    }
                }
                .padding(.top, 2)
            }
            Spacer()

            // Buttons
            HStack(spacing: 8) {
                Button {
                    // Action to open in browser
                    if let url = URL(string: repository.htmlUrl) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "safari")
                }
                .buttonStyle(.borderless)
                .help("Open in browser")

                Button {
                    // Action to clone
                    guard let cloneUrl = repository.cloneUrl else {
                        cloneErrorMessage = "Clone URL is not available for this repository."
                        showingCloneErrorAlert = true
                        return
                    }
                    // Present a panel to choose the directory
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    panel.prompt = "Choose Clone Destination"
                    panel.message = "Select a folder to clone '\(repository.name)' into."

                    if panel.runModal() == .OK {
                        if let destinationDirectory = panel.url {
                            Task {
                                do {
                                    let success = try await repoViewModel.cloneRepository(from: cloneUrl, to: destinationDirectory)
                                    if !success {
                                        cloneErrorMessage = repoViewModel.errorMessage ?? "Failed to clone repository."
                                        showingCloneErrorAlert = true
                                    }
                                } catch {
                                    cloneErrorMessage = "Error during cloning: \(error.localizedDescription)"
                                    showingCloneErrorAlert = true
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .help("Clone repository")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .alert("Clone Error", isPresented: $showingCloneErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cloneErrorMessage)
        }
    }

    // Basic language to color mapping (can be expanded or moved to a global helper)
    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "html": return .pink
        case "css": return .purple
        case "c#", "csharp": return .green
        case "c++", "cpp": return .pink
        case "ruby": return .red
        case "go": return .cyan
        case "typescript": return .blue
        case "php": return .purple
        case "scala": return .red
        case "kotlin": return Color(red: 0.6, green: 0.3, blue: 0.8) // A violet-ish color
        case "rust": return Color(red: 0.7, green: 0.3, blue: 0.1)
        default: return .gray
        }
    }
}

struct UpdateTokenView: View {
    @Environment(\.dismiss) var dismiss
    let account: Account
     var accountManager: AccountManager

    @State private var newToken: String = ""
    @State private var isUpdating: Bool = false
    @State private var updateError: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Update Token for \(account.username)")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading) {
                Text("New Personal Access Token").font(.headline)
                SecureField("Enter new token", text: $newToken)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Link("Create a token on GitHub", destination: URL(string: "https://github.com/settings/tokens/new?scopes=repo,user,gist,workflow")!)
                    .font(.caption)
            }

            if let updateError = updateError {
                Text(updateError)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: performUpdate) {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Update Token")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newToken.isEmpty || isUpdating)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
        .onChange(of: accountManager.errorMessage) { oldValue, newValue in
            if isUpdating { // Only update error if it pertains to the current update operation
                updateError = newValue
                if newValue == nil { // If error becomes nil, it means success
                    dismiss()
                }
                isUpdating = false // Reset updating state
            }
        }
        .onDisappear {
            if updateError != nil {
                accountManager.errorMessage = nil
            }
        }
    }

    private func performUpdate() {
        isUpdating = true
        updateError = nil
        accountManager.errorMessage = nil // Clear global error

        Task {
            await accountManager.updateAccountToken(accountID: account.id, newToken: newToken)
            // onChange for accountManager.errorMessage will handle UI update
        }
    }
}
