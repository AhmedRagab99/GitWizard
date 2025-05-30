import SwiftUI
import Foundation
import AppKit

// Import ThemeManager

struct GitClientView: View {
    @Bindable var viewModel: GitViewModel
    var themeManager = ThemeManager()
    var url: URL
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

    // Add a State variable for the AccountManager
    @State private var accountManager = AccountManager()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel, selectedWorkspaceItem: $selectedWorkspaceItem)
        } detail: {
            VStack(spacing: 0) {
                // Main content area
                if selectedWorkspaceItem == .workingCopy {
                    CommitView(viewModel: viewModel)
                } else if selectedWorkspaceItem == .history {
                    HistoryView(viewModel: viewModel)
                } else if selectedWorkspaceItem == .pullRequests {
                    PullRequestsContainerView(gitViewModel: viewModel)
                } else if selectedWorkspaceItem == .accounts { // Added Accounts view
                    AccountsListView(accountManager: accountManager)
                } else {
                    // Optionally, add a search view or placeholder
                    Text(" coming soon...")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search commits...")
        .searchScopes($showSearchFilters) {
            SearchFilterView(viewModel: viewModel)
        }
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            // Debounce search to avoid too many updates
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if viewModel.searchText == newValue { // Only proceed if the text hasn't changed
                    await viewModel.handleSearch(newValue)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Primary Actions Group
                Group {
                    // Theme Toggle
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
                            if  viewModel.pendingPushCount > 0 {
                                let count = viewModel.pendingPushCount
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Show commit sheet
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
                                Text("\(viewModel.pendingCommitsCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

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

                Divider()
                    .padding(.horizontal, 8)

                // Secondary Actions Group


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
        .loading(viewModel.isLoading)
        .errorAlert(viewModel.errorMessage)
        .sheet(isPresented: $showFetchSheet) {
            FetchSheet(
                isPresented: $showFetchSheet,
                remotes: viewModel.remoteNames,
                currentRemote: viewModel.remoteNames.first ?? "origin",
                onFetch: { remote, fetchAllRemotes, prune, fetchTags in
                    Task {
                        await viewModel.performFetch(
                            remote: remote,
                            fetchAllRemotes: fetchAllRemotes,
                            prune: prune,
                            fetchTags: fetchTags
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showPushSheet) {
            PushSheet(
                isPresented: $showPushSheet,
                branches: viewModel.branches,
                currentBranch: viewModel.currentBranch,
                onPush: { selectedBranches, pushTags in
                    Task {
                        for branch in selectedBranches {
                            await viewModel.push(branch: branch, pushTags: pushTags)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showStashSheet) {
            CreateStashSheet(
                isPresented: $showStashSheet,
                onStash: { message, keepStaged in
                    Task {
                        await viewModel.createStash(message: message, keepStaged: keepStaged)
                    }
                }
            )
        }
        .sheet(isPresented: $showPullSheet) {
            PullSheet(
                isPresented: $showPullSheet,
                remotes: ["origin"],
                remoteBranches: viewModel.remotebranches.map { $0.name },
                localBranches: viewModel.branches.map { $0.name },
                currentRemote: "origin",
                currentRemoteBranch: viewModel.currentBranch?.name ?? "",
                currentLocalBranch: viewModel.currentBranch?.name ?? "",
                onPull: { remote, remoteBranch, localBranch, options in
                    Task {
                        await viewModel.pull(remote: remote, remoteBranch: remoteBranch, localBranch: localBranch, options: options)
                    }
                }
            )
        }
        .sheet(isPresented: $showMergeSheet) {
            MergeSheet(
                viewModel: viewModel,
                isPresented: $showMergeSheet
            )
        }
        .sheet(isPresented: $showCreateBranchSheet) {
            CreateBranchSheet(
                isPresented: $showCreateBranchSheet,
                currentBranch: viewModel.currentBranch?.name ?? "",
                onCreate: { branchName, commitSource, specifiedCommit, checkout in
                    Task {
                        await viewModel.createBranch(named: branchName, checkout: checkout)
                    }
                }
            )
        }
        .sheet(isPresented: $showDeleteAlert) {
            DeleteBranchesView(
                isPresented: $showDeleteAlert,
                branches: viewModel.branches + viewModel.remotebranches,
                onDelete: { branches, deleteRemote, isRemote, forceDelete in
                    await viewModel.deleteBranches(branches, deleteRemote: deleteRemote, isRemote: isRemote, forceDelete: forceDelete)
                }
            )
        }
        .onAppear {
            viewModel.selectRepository(url)
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
//
//extension View {
//    func modernShadow(_ style: ModernUI.shadow) -> some View {
//        self.shadow(
//            color: .black.opacity(0.1),
//            radius: style.radius,
//            x: 0,
//            y: style.offset
//        )
//    }
//}




