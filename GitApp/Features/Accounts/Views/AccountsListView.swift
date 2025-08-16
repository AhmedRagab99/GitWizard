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
        .onFirstAppear {
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
                        AccountRow(
                            account: account,
                            selectedAccountID: $selectedAccountID,
                            onEditToken: {
                                accountToEdit = account
                            },
                            onDelete: {
                                accountToDelete = account
                                showDeleteConfirmation = true
                            }
                        )
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


// Ensure RepositoryListRow (previously RepositoryRow within AccountDetailView) is defined or adapted
// For simplicity, I'm renaming/defining a basic version here.
// You might need to adjust based on your existing RepositoryRow.



