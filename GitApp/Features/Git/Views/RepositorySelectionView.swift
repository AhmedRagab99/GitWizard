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
    private let gitService = GitService() // Add gitService instance

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
        Task { // Wrap in a Task for async operations
            let gitProviderService = GitProviderService()
            var pullRequestVM: PullRequestViewModel

            do {
                let remoteURLString = try await gitService.getRemoteURL(in: url)
                let parsedRemote = try GitURLParser.parse(remoteURL: remoteURLString)

                let matchedAccount = await findMatchingAccount(for: parsedRemote)
                pullRequestVM = createPullRequestViewModel(
                    for: url,
                    gitProviderService: gitProviderService,
                    matchedAccount: matchedAccount,
                    determinedRepoOwner: parsedRemote.owner,
                    determinedRepoName: parsedRemote.repoName
                )
            } catch {
                print("Error processing repository details for \(url.path) or creating PullRequestViewModel: \(error.localizedDescription). Using dummy VM.")
                pullRequestVM = createPullRequestViewModel(
                    for: url,
                    gitProviderService: gitProviderService,
                    matchedAccount: nil,
                    determinedRepoOwner: nil,
                    determinedRepoName: nil
                )
            }

            // UI updates must be on the main thread
            await MainActor.run {
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
                            pullRequestViewModel: pullRequestVM
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
    }

    private func findMatchingAccount(for parsedRemote: GitURLParser.ParsedURL) async -> Account? {
        for account in accountManager.accounts {
            var accountHost: String?
            switch account.type {
            case .githubCom:
                accountHost = "github.com"
            case .githubEnterprise:
                if let serverURL = account.serverURL, let enterpriseHost = URL(string: serverURL)?.host {
                    accountHost = enterpriseHost
                }
            }

            if let accHost = accountHost, accHost.lowercased() == parsedRemote.hostname.lowercased() {
                if var potentialMatch = accountManager.accounts.first(where: { $0.id == account.id }) {
                    if let token = accountManager.getToken(for: potentialMatch) {
                        potentialMatch.token = token
                        print("Found matching account: \(potentialMatch.username) for host \(parsedRemote.hostname)")
                        return potentialMatch
                    } else {
                        print("Error: Token not found for potentially matched account \(account.username) on host \(parsedRemote.hostname)")
                    }
                }
            }
        }
        print("Warning: No matching account found for remote host: \(parsedRemote.hostname)")
        return nil
    }

    private func createPullRequestViewModel(
        for localRepoURL: URL, // Added for context in logging if needed
        gitProviderService: GitProviderService,
        matchedAccount: Account?,
        determinedRepoOwner: String?,
        determinedRepoName: String?
    ) -> PullRequestViewModel {
        if let account = matchedAccount,
           let ownerName = determinedRepoOwner, !ownerName.isEmpty,
           let repoName = determinedRepoName, !repoName.isEmpty {

            let ownerUser = GitHubUser(
                id: 0, // Placeholder ID
                login: ownerName,
                avatarUrl: account.avatarURL, // Use account avatar, or fetch PR author specific later
                htmlUrl: "https://\(account.apiEndpoint?.host ?? "github.com")/\(ownerName)", // Construct carefully
                name: ownerName,
                company: nil, blog: nil, location: nil, email: nil, bio: nil,
                publicRepos: nil, followers: nil, following: nil
            )

            let githubRepo = GitHubRepository(
                id: Int.random(in: 1000...9999), // Placeholder ID
                name: repoName,
                fullName: "\(ownerName)/\(repoName)",
                owner: ownerUser,
                htmlUrl: "\(account.webURL?.absoluteString ?? "https://github.com")/\(ownerName)/\(repoName)", // Use account's webURL
                description: nil,
                sshUrl: nil,
                cloneUrl: "\(account.webURL?.absoluteString ?? "https://github.com")/\(ownerName)/\(repoName).git",
                stargazersCount: 0,
                watchersCount: 0,
                language: nil,
                forksCount: 0,
                openIssuesCount: 0,
                license: nil,
                isPrivate: false, // Placeholder
                defaultBranch: "main" // Placeholder
            )
            print("Successfully created PullRequestViewModel for \(ownerName)/\(repoName) with account \(account.username)")
            return PullRequestViewModel(gitProviderService: gitProviderService, account: account, repository: githubRepo)
        } else {
            print("Warning: Using dummy PullRequestViewModel. Repo URL: \(localRepoURL.path). Owner: \(determinedRepoOwner ?? "nil"), Repo: \(determinedRepoName ?? "nil"), Matched Account: \(matchedAccount?.username ?? "nil")")
            let dummyOwner = GitHubUser(id: -1, login: "unknown", avatarUrl: nil, htmlUrl: nil, name: "Unknown", company: nil, blog: nil, location: nil, email: nil, bio: nil, publicRepos: nil, followers: nil, following: nil)
            let dummyRepo = GitHubRepository(id: -1, name: "unknown", fullName: "unknown/unknown", owner: dummyOwner, htmlUrl: "", description: nil, sshUrl: nil, cloneUrl: nil, stargazersCount: 0, watchersCount: 0, language: nil, forksCount: 0, openIssuesCount: 0, license: nil, isPrivate: false, defaultBranch: "main")
            // Prefer first account, then a completely dummy one if no accounts exist.
            let fallbackAccount = accountManager.accounts.first ?? Account(type: .githubCom, username: "dummy", token: "dummy-token")
            return PullRequestViewModel(gitProviderService: gitProviderService, account: fallbackAccount, repository: dummyRepo)
        }
    }

}



