//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit

// Assuming RepositoryViewModel and AccountManager are defined elsewhere and are Observable
// If RepositoryViewModel is an @Observable class, this is fine.
// If AccountManager is an ObservableObject, it should be @ObservedObject or @StateObject.
// For this example, I'll assume they are correctly set up.

// Assuming these view models are correctly defined:
// import YourAppModule // Or ensure they are in the same module

enum RepositorySourceTab: String, CaseIterable, Identifiable {
    case recent = "Local"
    case accounts = "Remote"

    var id: String { self.rawValue }
}

struct RepositorySelectionView: View {
    @Bindable var viewModel: RepositoryViewModel
    @Bindable var accountManager :AccountManager
    @State private var selectedRepository: URL?
    @State private var isShowingFilePicker = false
    @State private var isShowingCloneSheet = false
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTab: RepositorySourceTab = .recent
    @State private var searchText: String = ""
    var themeManger: ThemeManager

    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    // Determine available tabs based on account presence
    private var availableTabs: [RepositorySourceTab] {
        if accountManager.accounts.isEmpty {
            return [.recent]
        }
        return RepositorySourceTab.allCases
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal)
                .padding(.bottom, 10)

            // Only show Picker if there are multiple sources (i.e., accounts exist)
            if !accountManager.accounts.isEmpty {
                Picker("Source", selection: $selectedTab) {
                    ForEach(availableTabs) { tab in // Use availableTabs
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 12)
            } else {
                // Add some spacing if picker is hidden, or adjust headerView padding
                Spacer(minLength: 12) // Placeholder for picker's bottom padding
            }

            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .searchable(text: $searchText, prompt: "Search Repositories")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .errorAlert(viewModel.errorMessage ?? errorMessage)
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositoryView(viewModel: viewModel, accountManager: accountManager, initialCloneURL: viewModel.cloneURL)
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Error", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {

            viewModel.loadRepositoryList()
            // Ensure selectedTab is valid if accounts are initially empty
            if accountManager.accounts.isEmpty && selectedTab == .accounts {
                selectedTab = .recent
            }
        }
        .onChange(of: accountManager.accounts) { _, newAccounts in
            // If all accounts are removed and "Accounts" tab was selected, switch to "Recent"
            if newAccounts.isEmpty && selectedTab == .accounts {
                selectedTab = .recent
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        // Show content based on selectedTab, but only show Accounts if accounts exist
        if selectedTab == .recent || accountManager.accounts.isEmpty {
            repositoryListView
        } else if selectedTab == .accounts && !accountManager.accounts.isEmpty {
            AccountRepositoriesListView(
                viewModel: viewModel,
                accountManager: accountManager,
                searchText: searchText,
                onCloneInitiated: { account, repo in
                    viewModel.cloneURL = repo.cloneUrl ?? ""
                    isShowingCloneSheet = true
                }
            )
        } else {
            // Fallback or empty view if needed, though logic should prevent this.
            // For safety, defaulting to recent.
            repositoryListView
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repositories")
                .font(.system(size: 28, weight: .bold))
                .padding(.top)

            HStack(spacing: 12) {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Label("Open Local", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("o", modifiers: .command)

                Button {
                    viewModel.cloneURL = ""
                    isShowingCloneSheet = true
                } label: {
                    Label("Clone Remote", systemImage: "icloud.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }

    private var filteredRecentRepositories: [URL] {
        if searchText.isEmpty {
            return viewModel.recentRepositories
        } else {
            return viewModel.recentRepositories.filter {
                $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var repositoryListView: some View {
        Group {
            let repositoriesToDisplay = filteredRecentRepositories
            if repositoriesToDisplay.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Recent Repositories", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Open a local repository or clone one from your accounts to see it here.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                List(selection: $selectedRepository) {
                    ForEach(repositoriesToDisplay, id: \.self) { url in
                        RepositoryRowView(
                            url: url,
                            isSelected: url == selectedRepository,
                            onOpen: {
                                handleWindow(with: url)
                            },
                            onRemove: {
                                viewModel.removeFromRecentRepositories(url)
                                if url == selectedRepository {
                                    selectedRepository = nil
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    }
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedRepository = url
                viewModel.addImportedRepository(url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isShowingErrorAlert = true
        }
    }

    private func handleWindow(with url: URL) {
        let windowId = url.lastPathComponent
        // Ensure GitProviderService is available
        let gitProviderService = GitProviderService()

        // Attempt to find a suitable account and repository details for PRs
        // This is a simplified approach. Robust implementation might require:
        // 1. GitService to fetch remote URL for the local repo.
        // 2. A parser for git remote URLs (e.g., https://github.com/owner/repo.git or git@github.com:owner/repo.git)
        // 3. Matching the parsed host with an account provider.

        // Placeholder: Try to find the first GitHub account
        var foundAccount = accountManager.accounts.first { $0.provider.lowercased().contains( "github") }
        let token = accountManager.getToken(for: foundAccount!)
        foundAccount?.token = token!
        
        // Placeholder: Create a GitHubRepository object.
        // In a real scenario, you'd parse owner/name from the local repo's remote URL.
        // For now, let's assume a function `createPlaceholderGitHubRepository(from: url, account: foundAccount)` exists or use dummy data.
        // This part is CRUCIAL for the PullRequestViewModel to function correctly.

        // Example of how you might try to get owner/repo (NEEDS ACTUAL IMPLEMENTATION)
        // let (owner, repoName) = getOwnerRepoFromLocalGitRepo(url: url) // This function needs to be created
        // For now, using placeholder values or attempting to derive from URL if it matches a known pattern.
        let (repoOwnerName, repoName) = (foundAccount?.username ?? "",url.lastPathComponent) // Simplified parsing

        var pullRequestVM: PullRequestViewModel?

        if let account = foundAccount, !repoOwnerName.isEmpty, !repoName.isEmpty {
            // Create a dummy GitHubUser for the owner if not available directly
            let ownerUser = GitHubUser(
                id: 0, // Placeholder ID
                login: repoOwnerName,
                avatarUrl: nil,
                htmlUrl: "https://github.com/\(repoOwnerName)", // Best guess
                name: repoOwnerName, // Or nil if not known
                company: nil,
                blog: nil,
                location: nil,
                email: nil,
                bio: nil,
                publicRepos: nil, // Use nil for optional Ints if unknown
                followers: nil,
                following: nil
            )
            let githubRepo = GitHubRepository(
                id: 0,
                name: repoName,
                fullName: "\(repoOwnerName)/\(repoName)",
                owner: ownerUser,
                htmlUrl: "https://github.com/\(repoOwnerName)/\(repoName)",
                description: nil, sshUrl: "Local repository",
                cloneUrl: "",
                stargazersCount: 0,
                watchersCount: 0,
                language: "",
                forksCount: 0,
                openIssuesCount: 0,
                license: nil,
                isPrivate: false,
                defaultBranch: nil
            )
            pullRequestVM = PullRequestViewModel(gitProviderService: gitProviderService, account: account, repository: githubRepo)
        }

        if isWindowVisible(id: windowId) {
            bringWindowToFront(id: windowId)
        } else {
            openNewWindow(
                with: GitClientView(
                    viewModel: GitViewModel(),
                    themeManager: themeManger,
                    url: url,
                    accountManager: accountManager,
                    repoViewModel: viewModel,
                    pullRequestViewModel: pullRequestVM // Force unwrap, as we provide a dummy if nil
                ),
                id: windowId,
                title: windowId,
                width: (NSScreen.main?.frame.width ?? 600) / 2,
                height: (NSScreen.main?.frame.height ?? 600) / 2
            )
        }

        print("Attempting to open window for: \(url.path) with ID: \(windowId)")
    }

}

struct RepositoryRowView: View {
    let url: URL
    let isSelected: Bool
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 25, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(url.lastPathComponent.replacingOccurrences(of: ".git", with: ""))
                    .font(.headline)
                    .fontWeight(.medium)
                Text(url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.init(nsColor: .selectedContentBackgroundColor).opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
            Button {
                onOpen()
            } label: {
                Label("Open Repo", systemImage: "folder")
            }

            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove from Recent", systemImage: "trash")
            }
        }
    }
}

