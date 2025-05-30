import SwiftUI

struct AccountsListView: View {
     var accountManager: AccountManager
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
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedAccountID) {
                    if accountManager.accounts.isEmpty {
                        Text("No accounts added yet.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(accountManager.accounts) {
                            account in AccountRow(account: account)
                                .tag(account.id)
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 200)

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
        } detail: {
            if let selectedID = selectedAccountID,
               let account = accountManager.accounts.first(where: { $0.id == selectedID }) {
                AccountDetailView(
                    account: account,
                    accountManager: accountManager,
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
        .navigationTitle("Accounts")
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

    var body: some View {
        HStack {
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
            VStack(alignment: .leading) {
                Text(account.username).font(.headline)
                Text(account.type.rawValue).font(.subheadline).foregroundColor(.secondary)
                if account.type == .githubEnterprise, let server = account.serverURL {
                    Text(URL(string: server)?.host ?? "Enterprise")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AccountDetailView: View {
    let account: Account
     var accountManager: AccountManager
    @Binding var repositories: [GitHubRepository]
    @Binding var isLoadingRepos: Bool
    @Binding var repoFetchError: String?
    var onUpdateToken: (Account) -> Void

    @State private var userDetails: GitHubUser? = nil
    @State private var isLoadingUserDetails: Bool = false

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

            TabView {
                accountInfoTab
                    .tabItem { Label("Account", systemImage: "person.text.rectangle.fill") }

                repositoriesTab
                    .tabItem { Label("Repositories", systemImage: "folder.fill") }
            }

            Spacer() // Pushes content to the top
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            fetchUserDetails()
        }
        .onChange(of: account) { _, newAccount in // React to account changes (e.g., after token update)
            fetchUserDetails(forAcc: newAccount)
            // Repositories are already re-fetched by the parent view's onChange(of: selectedAccountID)
        }
    }

    private var accountInfoTab: some View {
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

    private var repositoriesTab: some View {
        VStack(alignment: .leading) {
            if isLoadingRepos {
                ProgressView("Loading repositories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = repoFetchError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.largeTitle)
                        .padding(.bottom, 4)
                    Text("Error fetching repositories")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if repositories.isEmpty {
                Text("No repositories found for this account or you may not have access to any.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(repositories) { repo in
                    RepositoryRow(repo: repo)
                }
                .listStyle(.inset)
            }
        }
    }

    private func fetchUserDetails(forAcc: Account? = nil) {
        let targetAccount = forAcc ?? account
        isLoadingUserDetails = true
        Task {
            do {
                self.userDetails = try await accountManager.fetchUserDetails(for: targetAccount)
            } catch {
                print("Error fetching user details: \(error.localizedDescription)")
                // Optionally set an error message for user details fetching
            }
            isLoadingUserDetails = false
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

struct RepositoryRow: View {
    let repo: GitHubRepository

    var body: some View {
        HStack {
            Image(systemName: repo.isPrivate ? "lock.fill" : "folder.fill")
                .foregroundColor(repo.isPrivate ? .orange : .blue)
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 16) {
                    if let lang = repo.language {
                        Label(lang, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(languageColor(lang))
                    }
                    Label("\(repo.stargazersCount ?? 0)", systemImage: "star.fill")
                        .font(.caption2)
                    Label("\(repo.forksCount ?? 0)", systemImage: "arrow.triangle.branch")
                        .font(.caption2)
                }
            }
            Spacer()
            if let cloneURL = repo.cloneUrl {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cloneURL, forType: .string)
                    // Optionally show a toast/confirmation
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy HTTPS Clone URL")
            }
        }
        .padding(.vertical, 4)
    }

    // Basic language to color mapping (expand as needed)
    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "html": return .pink
        case "css": return .purple
        default: return .gray
        }
    }
}

#if DEBUG
struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockManager = AccountManager() // Create a new instance for preview
        if mockManager.accounts.isEmpty {
//            Task {
//                // Note: Previews don't have keychain access, so this won't fully work
//                // and addAccount also makes network calls.
//                // For true previews, you might need to inject mock data directly or mock services.
//                await mockManager.addAccount(type: .githubCom, username: "TestUser1", token: "dummytoken1")
//                await mockManager.addAccount(type: .githubEnterprise, username: "EntUser1", token: "dummytoken2", serverURL: "https://github.example.com")
//            }
        }

        return AccountsListView(accountManager: mockManager)
    }
}
#endif
