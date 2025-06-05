//
//  AccountRepositoriesListView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//


// GitApp/Features/Git/Views/AccountRepositoriesListView.swift
import SwiftUI

// Helper struct to organize repositories by source (Personal or Organization)
struct RepositorySection: Identifiable {
    let id = UUID()
    var name: String // "Personal" or Organization Name
    var repositories: [GitHubRepository]
    var isLoading: Bool = false // To show loading per section if desired
}

struct AccountRepositoriesListView: View {
    @State var viewModel: RepositoryViewModel
    @Bindable var accountManager: AccountManager
    var onCloneInitiated: (Account, GitHubRepository) -> Void

    @State private var selectedAccount: Account?
    @State private var repositorySections: [RepositorySection] = []
    @State private var isLoadingRepos = false // Overall loading for initial account selection
    @State private var repoErrorMessage: String?
    @State private var cloningRepositoryId: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if accountManager.accounts.isEmpty {
                noAccountsView
            } else {
                accountSelectionAndContentView
            }
        }
        .onAppear { // This onAppear is for the whole AccountRepositoriesListView
            if selectedAccount == nil, let firstAccount = accountManager.accounts.first {
                selectedAccount = firstAccount // Select first account automatically
            }
            // Fetching will be triggered by onChange of selectedAccount or if already selected
            if let currentAccount = selectedAccount, repositorySections.isEmpty && !isLoadingRepos {
                 Task { await fetchRepositories(for: currentAccount) }
            }
        }
        .onChange(of: selectedAccount) { _, newAccount in // Handles subsequent selections
             Task { await fetchRepositories(for: newAccount) }
        }
        .alert("Cloning Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil && cloningRepositoryId != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred during cloning.")
        }
    }

    // MARK: - Subviews
    private var noAccountsView: some View {
        ContentUnavailableView {
            Label("No Accounts", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("Add a GitHub or GitHub Enterprise account via settings to see your repositories.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial) // Subtle background for empty state
    }

    private var accountSelectionAndContentView: some View {
        VStack(alignment: .leading, spacing: 0) { // Use spacing 0 if dividers handle separation
            accountPickerView
                .padding(.horizontal) // Add padding around the picker
                .padding(.top)

            // Use a Group to conditionally show content without extra VStack
            Group {
                if isLoadingRepos && repositorySections.isEmpty { // Show main loader only if sections are empty
                    ProgressView("Loading account data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else if let errorMsg = repoErrorMessage, repositorySections.isEmpty {
                    ContentUnavailableView {
                        Label("Error Loading Repositories", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMsg)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if selectedAccount == nil && accountManager.accounts.count > 0 { // If accounts exist but none selected
                     ContentUnavailableView {
                        Label("Select an Account", systemImage: "hand.point.up.left.fill")
                    } description: {
                        Text("Choose an account above to view its repositories.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if repositorySections.isEmpty && !isLoadingRepos { // No repos and not loading
                    ContentUnavailableView {
                        Label("No Repositories", systemImage: "folder.fill.badge.questionmark")
                    } description: {
                         Text(selectedAccount != nil ? "No repositories found for \(selectedAccount!.displayName)." : "Select an account to see repositories.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    repositoriesListView
                }
            }
        }
    }

    private var accountPickerView: some View {
        Picker("Account:", selection: $selectedAccount) {
            // Placeholder for when no account is selected, useful if picker can be empty
            Text("Select an Account...").tag(nil as Account?)
            ForEach(accountManager.accounts) { account in
                HStack {
                               
                    Text(account.displayName)
                }
                .tag(account as Account?)
            }
        }
        .labelsHidden() // Hide the "Account:" label, text in picker items is enough
        .pickerStyle(.menu)
        .padding(.bottom, 8) // Add some space below the picker
    }

    private var repositoriesListView: some View {
        List {
            ForEach(repositorySections) { section in
                // Using a custom header view for better styling control
                Section {
                    ForEach(section.repositories) { repo in
                        repositoryRow(for: repo)
                    }
                } header: {
                    HStack {
                        Text(section.name)
                            .font(.title3) // Make section headers more prominent
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                        Spacer()
                        if section.isLoading { // Per-section loader
                            ProgressView().scaleEffect(0.7)
                        }
                    }
                    .padding(.leading, 5) // Indent section content slightly
                }
                .collapsible(false) // Make sections non-collapsible by default if desired
            }
        }
        .listStyle(.plain) // Plain can look more modern on macOS than inset for this type of list
        .background(.clear) // Ensure list background is clear if view has material
    }

    private func repositoryRow(for repo: GitHubRepository) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: repo.isPrivate ? "lock.rectangle.stack.fill" : "rectangle.stack.fill")
                .font(.title2)
                .foregroundColor(repo.isPrivate ? .orange : .blue)
                .frame(width: 25, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(repo.name)
                    .font(.headline)
                    .fontWeight(.medium)
                if let description = repo.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let cloneUrl = repo.cloneUrl {
                    Text(cloneUrl)
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            repositoryCloneStatusView(for: repo)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func repositoryCloneStatusView(for repo: GitHubRepository) -> some View {
        // Cloning status UI
        if cloningRepositoryId == repo.id.description && viewModel.isCloning {
            VStack(alignment: .trailing) {
                ProgressView(value: viewModel.cloneProgress)
                    .frame(width: 80)
                Text(viewModel.cloneStatus.isEmpty ? "Cloning..." : viewModel.cloneStatus)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else if isRepositoryCloned(repo) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Cloned")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        } else {
            Button {
                initiateClone(for: repo)
            } label: {
                Image(systemName: "icloud.and.arrow.down")
                    // .labelStyle(.iconOnly) // Alternative: Icon only
            }
            .buttonStyle(.borderless) // Borderless for subtle action in a list row
            .disabled(viewModel.isCloning && cloningRepositoryId != repo.id.description)
            .help("Clone \(repo.name)")
        }
    }

    // MARK: - Helper Methods
    private func fetchRepositories(for account: Account?) async { // This is the comprehensive fetch method
        guard let account = account else {
            repositorySections = []
            repoErrorMessage = nil
            isLoadingRepos = false // Ensure loading state is reset
            return
        }

        isLoadingRepos = true // Set overall loading state
        repoErrorMessage = nil
        var tempSections: [RepositorySection] = []

        do {
            // 1. Fetch Personal Repositories
            let personalRepos = try await accountManager.fetchRepositories(for: account)
            tempSections.append(RepositorySection(name: "Personal", repositories: personalRepos, isLoading: false))
            // Update UI incrementally ONLY if it's not the initial full load triggered by isLoadingRepos
            if !isLoadingRepos || self.repositorySections.isEmpty { // Avoid jumpy UI if already showing a loader
                 self.repositorySections = tempSections
            }


            // 2. Fetch Organizations
            let organizations = try await accountManager.fetchOrganizations(for: account)

            var orgSections: [RepositorySection] = []
            for org in organizations {
                // Create a placeholder section for the org while its repos are loading
                orgSections.append(RepositorySection(name: org.login, repositories: [], isLoading: true))
            }
            // Add all org placeholder sections at once
            if !orgSections.isEmpty {
                tempSections.append(contentsOf: orgSections)
                self.repositorySections = tempSections
            }


            // 3. Fetch Repositories for each Organization concurrently
            await withTaskGroup(of: (String, Result<[GitHubRepository], Error>).self) { group in
                for org in organizations {
                    group.addTask {
                        do {
                            let orgRepos = try await self.accountManager.fetchRepositories(for: account, organizationLogin: org.login)
                            return (org.login, .success(orgRepos))
                        } catch {
                            return (org.login, .failure(error))
                        }
                    }
                }

                for await (orgLogin, result) in group {
                    if let index = tempSections.firstIndex(where: { $0.name == orgLogin }) {
                        switch result {
                        case .success(let orgRepos):
                            tempSections[index].repositories = orgRepos
                            tempSections[index].isLoading = false
                        case .failure(let error):
                            print("Failed to fetch repos for org \(orgLogin): \(error.localizedDescription)")
                            tempSections[index].name = "\(orgLogin) (Error)" // Update name to indicate error
                            tempSections[index].isLoading = false
                        }
                         // Update sections in-place to avoid reordering or losing personal repos
                        self.repositorySections = tempSections.map { $0 } // Create new array to trigger update
                    }
                }
            }

        } catch {
            repoErrorMessage = "Failed to load account data: \(error.localizedDescription)"
            // Don't clear tempSections here, let it show what was fetched before error
        }
        isLoadingRepos = false // Clear overall loading state
        // If repositorySections is still empty and no error, it means no repos at all.
        // The ContentUnavailableView for "No Repositories Found" will handle this.
    }

    private func isRepositoryCloned(_ repo: GitHubRepository) -> Bool {
        let repoName = repo.name
        let cloneUrlString = repo.cloneUrl ?? ""

        // Check if a repository with the same name or clone URL exists in recent repositories
        return viewModel.recentRepositories.contains { recentRepoURL in
            let recentRepoName = recentRepoURL.lastPathComponent.replacingOccurrences(of: ".git", with: "")
            // A more robust check would be to compare the actual remote URL if available from the local .git config
            // For now, name matching is a simpler approach.
            // Also, check against the expected path if cloned via this UI
            let expectedClonedPathName = (URL(string: cloneUrlString)?.lastPathComponent.replacingOccurrences(of: ".git", with: ""))

            return recentRepoName.lowercased() == repoName.lowercased() ||
                   (expectedClonedPathName != nil && recentRepoName.lowercased() == expectedClonedPathName!.lowercased())
        }
    }

    private func initiateClone(for repo: GitHubRepository) {
        guard let account = selectedAccount, let cloneUrl = repo.cloneUrl else {
            viewModel.errorMessage = "Account or repository URL is missing."
            return
        }

        // Prevent multiple simultaneous clones from this view
        guard !viewModel.isCloning else {
            viewModel.errorMessage = "Another clone operation is already in progress."
            return
        }

        cloningRepositoryId = repo.id.description
        viewModel.cloneURL = cloneUrl // Ensure viewModel's cloneURL is set

        Task {
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                viewModel.errorMessage = "Could not access Documents directory."
                cloningRepositoryId = nil // Reset specific repo cloning state
                return
            }
            let clonesDirectory = documentsDirectory.appendingPathComponent("GitAppClones")
            if !fileManager.fileExists(atPath: clonesDirectory.path) {
                try? fileManager.createDirectory(at: clonesDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            // The RepositoryViewModel's cloneRepository method handles actual cloning
            // and updates isCloning, cloneProgress, cloneStatus.
            // It also handles adding to recentRepositories and saving.
            let success = try? await viewModel.cloneRepository(from: cloneUrl, to: clonesDirectory)

            if success != true {
                // viewModel.errorMessage should be set by cloneRepository on failure.
                // If not, provide a generic one here.
                if viewModel.errorMessage == nil {
                     viewModel.errorMessage = "Cloning '\(repo.name)' failed."
                }
            }
            // Reset specific repo cloning state whether success or failure,
            // as viewModel.isCloning will become false once the operation in viewModel finishes.
            cloningRepositoryId = nil
        }
    }
}
