import SwiftUI
import Combine
import Foundation
import Observation


// Remove Branch struct definition since it's now in Models/Branch.swift

// --- Git View Model ---

@Observable
class GitViewModel {
    // --- Published Properties (State) ---
     var repoInfo: RepoInfo = RepoInfo()
     var branches: [Branch] = []
     var remotebranches: [Branch] = []
     var tags: [Tag] = []
     var stashes: [Stash] = []
     var workspaceCommands: [WorkspaceCommand] = []
     var selectedSidebarItem: AnyHashable?
     var selectedCommit: Commit?
     var selectedFileDiff: FileDiff?
     var diffContent: Diff?
     var isLoading: Bool = false
     var errorMessage: String?
     var repositoryURL: URL? {
        didSet {
            if let url = repositoryURL {
                Task {
                    await loadRepositoryData(from: url)
                }
            }
        }
    }
     var foundRepositories: [URL] = []
     var isSearchingRepositories = false
     var permissionError: String?
     var isCloning = false
     var cloneProgress: Double = 0.0
     var cloneStatus: String = ""
     var cloneURL: String = ""
     var cloneDirectory: URL?
     var isShowingCloneSheet = false
     var isShowingImportSheet = false
     var isAddingLocalRepo = false
     var isShowingAddLocalSheet = false
     var localRepoPath: URL?
     var localRepoName: String = ""
     var importProgress: ImportProgress?
     var isImporting = false
     var importStatus: String = ""
     var selectedBranch: Branch? {
        didSet {
            if let branch = selectedBranch, let url = repositoryURL {
                loadCommits(for: branch, in: url)
            }
        }
    }
     var currentBranch: Branch?
     var commitDetails: CommitDetails?
     var clonedRepositories: [URL] = []
     var importedRepositories: [URL] = []
     var selectedRepository: URL?
     var stagedDiff: Diff?
     var unstagedDiff: Diff?
     var untrackedFiles: [String] = []
     var recentRepositories: [URL] = []
    var syncState = SyncState()
    var commits = [Commit]()

    // Add LogStore
    let logStore = LogStore()

    struct ImportProgress: Identifiable {
        let id = UUID()
        var current: Int
        var total: Int
        var status: String
    }

    private var cancellables = Set<AnyCancellable>()
    private let gitService = GitService()

    init() {
        setupBindings()
        loadWorkspaceCommands()
        loadRepositoryList()
    }

    func isGitRepository(at: URL) async -> Bool {
            return try await gitService.isGitRepository(at: at)
    }

    private func loadWorkspaceCommands() {
        workspaceCommands = [
            WorkspaceCommand(name: "Fetch", icon: "arrow.triangle.2.circlepath"),
            WorkspaceCommand(name: "Pull", icon: "arrow.down.circle"),
            WorkspaceCommand(name: "Push", icon: "arrow.up.circle"),
            WorkspaceCommand(name: "Commit", icon: "checkmark.circle")
        ]
    }

    // --- Public Methods ---
    func loadRepositoryData(from url: URL) async {
        do {
            guard  await gitService.isGitRepository(at: url) else {
                errorMessage = "Selected directory is not a Git repository"
                return
            }

            isLoading = true
            defer { isLoading = false }

            // Load data in parallel where possible
            async let branchesTask = gitService.getBranches(in: url)
            async let currentBranchTask = gitService.getCurrentBranch(in: url)
            async let tagsTask = gitService.getTags(in: url)
            async let stashesTask = gitService.getStashes(in: url)
            async let remotesTask = gitService.getRemotes(in: url)

            // Wait for all parallel tasks to complete
            let (branches, currentBranchName, tags, stashes, remotes) = try await (
                branchesTask,
                currentBranchTask,
                tagsTask,
                stashesTask,
                remotesTask
            )

            // Update branches
            self.branches = branches
            self.remotebranches = remotes

            // Set current branch and update related state
            if let currentBranchName = currentBranchName {
                currentBranch = branches.first { $0.name == currentBranchName }
                selectedBranch = currentBranch
                await MainActor.run {
                    syncState.branch = currentBranch
                    syncState.folderURL = url

                    // Update LogStore with current branch
                    logStore.directory = url
                    logStore.searchTokens = [SearchToken(kind: .revisionRange, text: currentBranchName)]
                }
                await logStore.refresh()
            }

            // Update other repository data
            self.tags = tags
            self.stashes = stashes

            // Update repository info
            repoInfo = RepoInfo(
                name: url.lastPathComponent,
                currentBranch: currentBranchName ?? "main",
                remotes: remotes
            )

            // Check sync state
            try await syncState.sync()

        } catch {
            errorMessage = "Error loading repository data: \(error.localizedDescription)"
        }
    }

    private func gatherRepositoryInfo(from url: URL) async -> RepoInfo {
        do {
            // Get repository name
            let name = url.lastPathComponent

            // Get current branch
            let currentBranch = try await gitService.getCurrentBranch(in: url) ?? "main"

            // Get remote information
            let remotes = try await gitService.getRemotes(in: url)

            return RepoInfo(
                name: name,
                currentBranch: currentBranch,
                remotes: remotes
            )
        } catch {
            errorMessage = "Error gathering repository info: \(error.localizedDescription)"
            return RepoInfo()
        }
    }

    private func loadCommits(for branch: Branch, in url: URL) {
        Task {
            do {
                isLoading = true
                defer { isLoading = false }

                // Update LogStore with branch
                logStore.searchTokens = [SearchToken(kind: .revisionRange, text: branch.name)]
                await logStore.refresh()
            } catch {
                errorMessage = "Error loading commits: \(error.localizedDescription)"
            }
        }
    }

    // --- Bindings Setup ---
    private func setupBindings() {
        // Use Combine's publisher for selectedFileDiff
        NotificationCenter.default.publisher(for: NSNotification.Name("SelectedFileDiffChanged"))
            .compactMap { notification -> FileDiff? in
                return notification.object as? FileDiff
            }
            .sink { [weak self] fileDiff in
                guard let self = self,
                      let commit = self.selectedCommit,
                      let url = self.repositoryURL else { return }

                self.isLoading = true
                defer { self.isLoading = false }

                Task {
                    do {
                        let diff = try await self.gitService.getDiff(in: url)
                        self.diffContent = diff
                    } catch {
                        self.errorMessage = "Error loading diff: \(error.localizedDescription)"
                    }
                }
            }
            .store(in: &cancellables)

        // Use Combine's publisher for selectedCommit
        NotificationCenter.default.publisher(for: NSNotification.Name("SelectedCommitChanged"))
            .compactMap { notification -> Commit? in
                return notification.object as? Commit
            }
            .sink { [weak self] commit in
                guard let self = self else { return }
                if commit == nil {
                    self.selectedFileDiff = nil
                    self.diffContent = nil
                    self.commitDetails = nil
                } else if let url = self.repositoryURL {
                    Task {
                        await self.loadCommitDetails(commit, in: url)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // Helper methods to post notifications
    func notifySelectedFileDiffChanged(_ fileDiff: FileDiff?) {
        NotificationCenter.default.post(name: NSNotification.Name("SelectedFileDiffChanged"), object: fileDiff)
    }

    func notifySelectedCommitChanged(_ commit: Commit?) {
        NotificationCenter.default.post(name: NSNotification.Name("SelectedCommitChanged"), object: commit)
    }

    // --- Git Actions ---
    func performFetch() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.fetch(in: url)
            // Refresh repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Fetch failed: \(error.localizedDescription)"
        }
    }

    func performPull() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.pull(in: url)
            // Refresh repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Pull failed: \(error.localizedDescription)"
        }
    }


    func performPush() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.push(in: url)
        } catch {
            errorMessage = "Push failed: \(error.localizedDescription)"
        }
    }

    func performCommit() async {
        errorMessage = "Commit functionality not implemented yet"
    }

    func searchForRepositories(in directory: URL) {
        isSearchingRepositories = true
        defer { isSearchingRepositories = false }

        Task {
            do {
                foundRepositories = try await gitService.findGitRepositories(in: directory)
                if foundRepositories.isEmpty {
                    errorMessage = "No Git repositories found in the selected directory"
                }
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain && error.code == 257 {
                    permissionError = "Permission denied to access \(directory.lastPathComponent). Please grant access in System Settings."
                } else {
                    errorMessage = "Error searching directories: \(error.localizedDescription)"
                }
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
        }
    }

    func removeFromRecentRepositories(_ url: URL) {
        recentRepositories.removeAll { $0 == url }
        saveRecentRepositories()
    }

    func cloneRepository(from url: String, to directory: URL) async throws -> Bool {
        guard !url.isEmpty else {
            errorMessage = "Please enter a repository URL"
            return false
        }

        isCloning = true
        cloneProgress = 0.0
        cloneStatus = "Starting clone..."

        defer {
            isCloning = false
            cloneProgress = 0.0
            cloneStatus = ""
        }

        do {
            let success = try await gitService.cloneRepository(from: url, to: directory)

            if success {
                let repoName = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? "repository"
                let repoPath = directory.appendingPathComponent(repoName)

                // Add to cloned repositories
                addClonedRepository(repoPath)

                // Set as current repository and selected repository
                repositoryURL = repoPath
                selectedRepository = repoPath

                // Add to recent repositories
                if !recentRepositories.contains(repoPath) {
                    recentRepositories.insert(repoPath, at: 0)
                    if recentRepositories.count > 10 {
                        recentRepositories.removeLast()
                    }
                    saveRecentRepositories()
                }

                // Load repository data
                await loadRepositoryData(from: repoPath)

                // Update progress
                cloneProgress = 1.0
                cloneStatus = "Clone completed successfully"

                return true
            }
            return false
        } catch {
            errorMessage = "Clone failed: \(error.localizedDescription)"
            return false
        }
    }

    func importRepository(from url: URL) {
        Task {
            do {
                if try await gitService.isGitRepository(at: url) {
                    addImportedRepository(url)
                    repositoryURL = url
                    isShowingImportSheet = false
                    await loadRepositoryData(from: url)
                } else {
                    errorMessage = "Selected directory is not a Git repository"
                }
            } catch {
                errorMessage = "Error importing repository: \(error.localizedDescription)"
            }
        }
    }

    func addLocalRepository(at url: URL) async {
        isImporting = true
        importProgress = ImportProgress(current: 0, total: 100, status: "Preparing repository...")

        do {
            // Validate Git repository
            importStatus = "Validating Git repository..."
            guard try await gitService.isGitRepository(at: url) else {
                errorMessage = "Selected directory is not a Git repository"
                isImporting = false
                importProgress = nil
                return
            }

            // Set as current repository
            repositoryURL = url

            // Load repository data
            await loadRepositoryData(from: url)

            isShowingAddLocalSheet = false
        } catch {
            errorMessage = "Failed to add repository: \(error.localizedDescription)"
        }

        isImporting = false
        importProgress = nil
    }

    func loadCommitDetails(_ commit: Commit, in url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get full commit details
             let details = try await gitService.getCommitDetails(commit.hash, in: url)
                commitDetails = details

        } catch {
            errorMessage = "Error loading commit details: \(error.localizedDescription)"
        }
    }

    private func saveRepositoryList() {
        let encoder = JSONEncoder()
        do {
            let clonedData = try encoder.encode(clonedRepositories.map { $0.path })
            let importedData = try encoder.encode(importedRepositories.map { $0.path })
            UserDefaults.standard.set(clonedData, forKey: "clonedRepositories")
            UserDefaults.standard.set(importedData, forKey: "importedRepositories")
        } catch {
            print("Failed to save repository list: \(error)")
        }
    }

    private func loadRepositoryList() {
        let decoder = JSONDecoder()
        if let clonedData = UserDefaults.standard.data(forKey: "clonedRepositories"),
           let importedData = UserDefaults.standard.data(forKey: "importedRepositories") {
            do {
                let clonedPaths = try decoder.decode([String].self, from: clonedData)
                let importedPaths = try decoder.decode([String].self, from: importedData)
                clonedRepositories = clonedPaths.map { URL(fileURLWithPath: $0) }
                importedRepositories = importedPaths.map { URL(fileURLWithPath: $0) }
            } catch {
                print("Failed to load repository list: \(error)")
            }
        }
    }

    func addClonedRepository(_ url: URL) {
        if !clonedRepositories.contains(url) {
            clonedRepositories.append(url)
            saveRepositoryList()
        }
    }

    func addImportedRepository(_ url: URL) {
        if !importedRepositories.contains(url) {
            importedRepositories.append(url)
            saveRepositoryList()
        }
    }

    func selectRepository(_ url: URL) {
        selectedRepository = url
        repositoryURL = url
        Task {
            await loadRepositoryData(from: url)
        }
    }

    func loadChanges() async {
        guard let url = repositoryURL else { return }
        do {
            let status = try await gitService.getStatus(in: url)

            // Get staged changes
            let stagedDiff = try await gitService.getDiff(in: url, cached: true)
            self.stagedDiff = stagedDiff

            // Get unstaged changes
            let unstagedDiff = try await gitService.getDiff(in: url, cached: false)
            self.unstagedDiff = unstagedDiff

            // Update untracked files
            self.untrackedFiles = status.untrackedFiles

            // Update selected file diff if needed
            if let selectedPath = selectedFileDiff?.fromFilePath {
                if let stagedFile = stagedDiff.fileDiffs.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileDiff = stagedFile
                } else if let unstagedFile = unstagedDiff.fileDiffs.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileDiff = unstagedFile
                }
            }
        } catch {
            print("Error loading changes: \(error)")
        }
    }

    func stageChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.stageChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error staging chunk: \(error.localizedDescription)"
            }
        }
    }

    func unstageChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.unstageChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging chunk: \(error.localizedDescription)"
            }
        }
    }

    func unstageFile(path: String) async {
        guard let url = repositoryURL else { return }

        do {
            try await gitService.unstageFile(path, in: url)
            await loadChanges()
        } catch {
            errorMessage = "Error unstaging file: \(error.localizedDescription)"
        }
    }

    func stageFile(path: String) async {
        guard let url = repositoryURL else { return }

        do {
            try await gitService.addFiles(in: url, pathspec: path)
            await loadChanges()
        } catch {
            errorMessage = "Error staging file: \(error.localizedDescription)"
        }
    }

    func resetChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.resetChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error resetting chunk: \(error.localizedDescription)"
            }
        }
    }

    func stageAllChanges() async {
            do {
                guard let url = repositoryURL else { return }
                try await gitService.stageAllChanges(in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error staging changes: \(error.localizedDescription)"
            }
    }

    func unstageAllChanges() async {
        guard let url = repositoryURL else { return }
            do {
                try await gitService.unstageAllChanges(in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging all changes: \(error.localizedDescription)"
            }

    }

    func commitChanges(message: String) async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.commitChanges(in: url, message: message)

            // Reload repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Error committing changes: \(error.localizedDescription)"
        }
    }

    func checkoutBranch(_ branch: Branch,isRemote: Bool = false) async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isRemote {
                try await gitService.checkoutBranch(to: branch, in: url)
            } else {
                try await gitService.switchBranch(to: branch.name, in: url)
            }
            currentBranch = branch
            selectedBranch = branch
            syncState.branch = branch

            // Update LogStore with new branch
            logStore.searchTokens = [SearchToken(kind: .revisionRange, text: branch.name)]

            // Check sync state
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Checkout failed: \(error.localizedDescription)"
        }
    }

    func openRepository(at url: URL) async throws {
        do {
            guard try await gitService.isGitRepository(at: url) else {
                throw NSError(domain: "GitApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Selected directory is not a Git repository"])
            }

            // Add to recent repositories if not already present
            if !recentRepositories.contains(url) {
                recentRepositories.insert(url, at: 0)
                // Keep only the last 10 repositories
                if recentRepositories.count > 10 {
                    recentRepositories.removeLast()
                }
                saveRecentRepositories()
            }

            // Set as current repository
            repositoryURL = url

            // Load repository data
            await loadRepositoryData(from: url)
        } catch {
            throw error
        }
    }

    func loadRecentRepositories() async {
        if let data = UserDefaults.standard.data(forKey: "recentRepositories") {
            do {
                let paths = try JSONDecoder().decode([String].self, from: data)
                recentRepositories = paths.map { URL(fileURLWithPath: $0) }

                // Validate repositories still exist and are valid
                recentRepositories = recentRepositories.filter { url in
                    var isDirectory: ObjCBool = false
                    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    return exists && isDirectory.boolValue
                }

                saveRecentRepositories()
            } catch {
                print("Error loading recent repositories: \(error)")
            }
        }
    }

    private func saveRecentRepositories() {
        do {
            let paths = recentRepositories.map { $0.path }
            let data = try JSONEncoder().encode(paths)
            UserDefaults.standard.set(data, forKey: "recentRepositories")
        } catch {
            print("Error saving recent repositories: \(error)")
        }
    }

    func refreshState() async {
        guard let url = repositoryURL else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Refresh repository data
            await loadRepositoryData(from: url)

            // Refresh changes
            await loadChanges()

            // Refresh current branch
            if let currentBranchName = try await gitService.getCurrentBranch(in: url) {
                currentBranch = branches.first { $0.name == currentBranchName }
                selectedBranch = currentBranch

                // Update LogStore
                logStore.searchTokens = [SearchToken(kind: .revisionRange, text: currentBranchName)]
                await logStore.refresh()
            }
        } catch {
            errorMessage = "Error refreshing state: \(error.localizedDescription)"
        }
    }

    func checkoutCommit(_ hash: String) async {
        guard let repoURL = selectedRepository else {
            errorMessage = "No repository selected"
            return
        }

        do {
            try await gitService.checkoutCommit(hash, in: repoURL)
            // Refresh the state
            await refreshState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Branch Operations
    func switchBranch(to branch: Branch) async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.switchBranch(to: branch.name, in: url)
            currentBranch = branch
            selectedBranch = branch
            syncState.branch = branch

            // Update LogStore with new branch
            logStore.searchTokens = [SearchToken(kind: .revisionRange, text: branch.name)]
            await logStore.refresh()

            // Check sync state
            try await syncState.sync()
        } catch {
            errorMessage = "Error switching branch: \(error.localizedDescription)"
        }
    }

    // MARK: - Sync Operations
    func pull() async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.pull(in: url)
            try await syncState.sync()

            // Reload repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Error pulling changes: \(error.localizedDescription)"
        }
    }

    func push() async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.push(in: url)
            try await syncState.sync()
        } catch {
            errorMessage = "Error pushing changes: \(error.localizedDescription)"
        }
    }

    // MARK: - File Operations
    func getStatus() async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            let status = try await gitService.getStatus(in: url)

        } catch {
            errorMessage = "Error getting status: \(error.localizedDescription)"
        }
    }

    func addFiles(pathspec: String? = nil) async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.addFiles(in: url, pathspec: pathspec)
            await getStatus()
        } catch {
            errorMessage = "Error adding files: \(error.localizedDescription)"
        }
    }

    func copyCommitHash(_ hash: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(hash, forType: .string)
    }

    func checkoutCommit(_ commit: Commit) {
        Task {
            do {
                guard let url = repositoryURL else { return }
                try await gitService.checkoutCommit(commit.hash, in: url)
                await loadRepositoryData(from: url)
            } catch {
                errorMessage = "Error checking out commit: \(error.localizedDescription)"
            }
        }
    }



    func loadCommitDetails(_ commit: Commit) {
        Task {
            guard let url = repositoryURL else { return }
            await loadCommitDetails(commit, in: url)
        }
    }


}
