import SwiftUI
import Foundation
import AppKit

// Import ThemeManager

public extension View {
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }
}

private struct FirstAppear: ViewModifier {
    let action: () -> ()

    // Use this to only fire your block one time
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        // And then, track it here
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

// Update WorkspaceSidebarItem to include blame and search
enum WorkspaceSidebarItem: String, CaseIterable, Identifiable {
    case workingCopy = "Working Copy"
    case history = "History"
    case pullRequests = "Pull Requests"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .workingCopy: return "arrow.triangle.branch"
        case .history: return "clock"
        case .pullRequests: return "arrow.triangle.pull"
        }
    }
}

struct GitClientView: View {
     var viewModel: GitViewModel
    var themeManager : ThemeManager
     var accountManager: AccountManager
    var repoViewModel : RepositoryViewModel // Add view model
    var pullRequestViewModel: PullRequestViewModel?
    @State private var selectedWorkspaceItem: WorkspaceSidebarItem = .history
    @State private var showStashSheet = false
    @State private var showDeleteAlert = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showCreateBranchSheet = false
    @State private var newBranchName = ""
    @State private var stashMessage = ""
    @State private var keepStaged = false
    @State private var showPushSheet = false
    @State private var showPullSheet = false
    @State private var showMergeSheet = false
    @State private var showFetchSheet = false
    @State private var showSearchFilters = false
    @State private var selectedFilePath: String?

    var body: some View {
        mainContent
            .loading(viewModel.isLoading)
            .errorAlert(viewModel.errorMessage)
            .presentFetchSheet(
                isPresented: $showFetchSheet,
                remotes: viewModel.remoteNames,
                currentRemote: viewModel.remoteNames.first ?? "origin",
                onFetch: handleFetch
            )
            .presentPushSheet(
                isPresented: $showPushSheet,
                branches: viewModel.branches,
                currentBranch: viewModel.currentBranch,
                onPush: handlePush
            )
            .presentCreateStashSheet(
                isPresented: $showStashSheet,
                onStash: handleStash
            )
            .presentPullSheet(
                isPresented: $showPullSheet,
                remotes: ["origin"],
                remoteBranches: viewModel.remotebranches.map { $0.name },
                localBranches: viewModel.branches.map { $0.name },
                currentRemote: "origin",
                currentRemoteBranch: viewModel.currentBranch?.name ?? "",
                currentLocalBranch: viewModel.currentBranch?.name ?? "",
                onPull: handlePull
            )
            .presentMergeSheet(
                isPresented: $showMergeSheet,
                viewModel: viewModel
            )
            .presentCreateBranchSheet(
                isPresented: $showCreateBranchSheet,
                currentBranch: viewModel.currentBranch?.name ?? "",
                onCreate: handleCreateBranch
            )
            .presentDeleteBranchesSheet(
                isPresented: $showDeleteAlert,
                branches: viewModel.branches + viewModel.remotebranches,
                onDelete: handleDeleteBranches
            )
            .onFirstAppear {
                Task {
                    await viewModel.selectRepository()
                }
            }

    }

    // Split the main content into a computed property
    private var mainContent: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel, selectedWorkspaceItem: $selectedWorkspaceItem)
        } detail: {
            detailContent
        }
        .searchable(text: Binding(get:{viewModel.searchText},set:{viewModel.searchText = $0}), prompt: "Search commits...")
        .searchScopes($showSearchFilters) {
            SearchFilterView(viewModel: viewModel)
        }
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            handleSearchTextChange(newValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtonsContent
            }
        }
    }

    // Split detail content into its own view
    private var detailContent: some View {
        VStack(spacing: 0) {
            if selectedWorkspaceItem == .workingCopy {
                CommitView(viewModel: viewModel)
            } else if selectedWorkspaceItem == .history {
                HistoryView(viewModel: viewModel)
            } else if selectedWorkspaceItem == .pullRequests {
                PullRequestsListView(viewModel: getVM(), accountManager: accountManager)
            } else {
                Text("Coming soon...")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func getVM() -> PullRequestViewModel {
        let pullRequestVM = PullRequestViewModel()
        let remoteURL = viewModel.repoInfo.remoteURL

        // Create a GitHubRepository from the remoteURL
        let repoOwner = remoteURL.components(separatedBy: "/").dropLast().last ?? ""
        let repoName = remoteURL.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? ""

        let repository = GitHubRepository(
            id: 0,
            name: repoName,
            fullName: "\(repoOwner)/\(repoName)",
            owner: GitHubUser(
                id: 0,
                login: repoOwner,
                avatarUrl: nil,
                htmlUrl: nil,
                name: nil,
                company: nil,
                blog: nil,
                location: nil,
                email: nil,
                bio: nil,
                publicRepos: 0,
                followers: 0,
                following: 0
            ),
            htmlUrl: remoteURL ?? "",
            description: nil,
            sshUrl: nil,
            cloneUrl: remoteURL,
            stargazersCount: nil,
            watchersCount: nil,
            language: nil,
            forksCount: nil,
            openIssuesCount: nil,
            license: nil,
            isPrivate: false,
            defaultBranch: viewModel.currentBranch?.name
        )

        pullRequestVM.repository = repository
        pullRequestVM.initData(repository: repository, accountManager: accountManager)
        return pullRequestVM
    }

    // Handle search text changes
    private func handleSearchTextChange(_ newValue: String) {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if viewModel.searchText == newValue { // Only proceed if the text hasn't changed
                await viewModel.handleSearch(newValue)
            }
        }
    }

    
    
    
    
    
    
    
    // Toolbar buttons content
    private var toolbarButtonsContent: some View {
        Group {
            themeToggleButton
            fetchButton
            pullButton
            mergeButton
            pushButton
            commitButton
            newBranchButton
            stashButton

            Divider()
                .padding(.horizontal, 8)

            deleteButton
        }
    }

    private var themeToggleButton: some View {
        Button(action: {
            themeManager.isDarkMode.toggle()
        }) {
            VStack(spacing: 4) {
                Image(systemName:"sun.max.fill")
                    .font(.system(size: 20))
                Text("Switch Theme")
                    .font(.caption)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .help("Switch Theme")
    }

    private var fetchButton: some View {
        Button(action: {
            showFetchSheet = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20))
                Text("Fetch")
                    .font(.caption)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .help("Fetch from Remote")
    }

    private var pullButton: some View {
        Button(action: {
            showPullSheet = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20))
                Text("Pull")
                    .font(.caption)
            }
            .frame(width: 60)
            .overlay(alignment: .topTrailing) {
                if viewModel.syncState.shouldPull {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var mergeButton: some View {
        Button(action: {
            showMergeSheet = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 20))
                Text("Merge")
                    .font(.caption)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }

    private var pushButton: some View {
        Button(action: {
            showPushSheet = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                Text("Push")
                    .font(.caption)
            }
            .frame(width: 60)
            .overlay(alignment: .topTrailing) {
                if viewModel.pendingPushCount > 0 {
                    CountBadge(count: viewModel.pendingPushCount)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var commitButton: some View {
        Button(action: {
            selectedWorkspaceItem = .workingCopy
        }) {
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Commit")
                    .font(.caption)
            }
            .frame(width: 60)
            .overlay(alignment: .topTrailing) {
                if viewModel.pendingCommitsCount > 0 {
                    CountBadge(count: viewModel.pendingCommitsCount)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var newBranchButton: some View {
        Button(action: {
            showCreateBranchSheet = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "plus.square.on.square")
                    .font(.system(size: 20))
                Text("New Branch")
                    .font(.caption)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }

    private var stashButton: some View {
        Button(action: { showStashSheet = true }) {
            VStack(spacing: 4) {
                Image(systemName: "archivebox")
                    .font(.system(size: 20))
                Text("Stash")
                    .font(.caption)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button(action: {
            showDeleteAlert = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                Text("Delete")
                    .font(.caption)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

// Extension to apply all sheet presenters cleanly
extension GitClientView {

    private func handleFetch(remote: String, fetchAllRemotes: Bool, prune: Bool, fetchTags: Bool) {
        Task {
            await viewModel.performFetch(
                remote: remote,
                fetchAllRemotes: fetchAllRemotes,
                prune: prune,
                fetchTags: fetchTags
            )
        }
    }

    private func handlePush(selectedBranches: [Branch], pushTags: Bool) {
        Task {
            for branch in selectedBranches {
                await viewModel.push(branch: branch, pushTags: pushTags)
            }
        }
    }

    private func handleStash(message: String, keepStaged: Bool) {
        Task {
            await viewModel.createStash(message: message, keepStaged: keepStaged)
        }
    }

    private func handlePull(remote: String, remoteBranch: String, localBranch: String, options: PullSheet.PullOptions) {
        Task {
            await viewModel.pull(remote: remote, remoteBranch: remoteBranch, localBranch: localBranch, options: options)
        }
    }

    private func handleCreateBranch(branchName: String, commitSource: CommitSource, specifiedCommit: String?, checkout: Bool) {
        Task {
            await viewModel.createBranch(named: branchName, checkout: checkout)
        }
    }

    // Modified to return a non-async function wrapper that calls the async method inside a Task
    private func handleDeleteBranches(branches: [Branch], deleteRemote: Bool, isRemote: Bool, forceDelete: Bool) {
        Task {
            await viewModel.deleteBranches(branches, deleteRemote: deleteRemote, isRemote: isRemote, forceDelete: forceDelete)
        }
    }
}

struct SearchFilterView: View {
    @Bindable var viewModel: GitViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Author filter
            HStack {
                Text("Author:")
                    .foregroundStyle(.secondary)
                TextField("Filter by author", text: $viewModel.searchAuthor)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.searchAuthor) { _, _ in
                        Task {
                            await viewModel.handleSearch(viewModel.searchText)
                        }
                    }
            }

            // Content filter
            HStack {
                Text("Content:")
                    .foregroundStyle(.secondary)
                TextField("Filter by content", text: $viewModel.searchContent)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.searchContent) { _, _ in
                        Task {
                            await viewModel.handleSearch(viewModel.searchText)
                        }
                    }
            }

            // All match toggle
            Toggle("Match all filters", isOn: $viewModel.searchAllMatch)
                .onChange(of: viewModel.searchAllMatch) { _, _ in
                    Task {
                        await viewModel.handleSearch(viewModel.searchText)
                    }
                }

            // Reset button
            Button("Reset Filters") {
                Task {
                    await viewModel.resetSearch()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300)
    }
}

// Syntax Highlighting Colors
enum SyntaxTheme {
    static let added = Color.green.opacity(0.1)
    static let removed = Color.red.opacity(0.1)
    static let lineNumber = Color.gray.opacity(0.5)
    static let addedText = Color.green
    static let removedText = Color.red
    static let normalText = Color.clear
}

// Modern UI Constants
enum ModernUI {
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
    static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    enum colors {
        static let background = Color(.windowBackgroundColor)
        static let secondaryBackground = Color(.controlBackgroundColor)
        static let selection = Color(.selectedContentBackgroundColor)
        static let border = Color(.separatorColor)
        static let secondaryText = Color(.secondaryLabelColor)
    }

    enum shadow {
        case small, medium, large

        var radius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 8
            }
        }
        var colors: Color {
            switch self {
                case .small: return Color.black.opacity(0.1)
                case .medium: return Color.black.opacity(0.2)
            case .large: return Color.black.opacity(0.3)
            }
        }


        var offset: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return 4
            }
        }
    }
}



