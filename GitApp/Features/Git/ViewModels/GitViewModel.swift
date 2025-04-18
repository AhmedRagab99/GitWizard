import SwiftUI
import Combine
import Foundation

// Remove Branch struct definition since it's now in Models/Branch.swift

// --- Git View Model ---
@MainActor
class GitViewModel: ObservableObject {
    // --- Published Properties (State) ---
    @Published var repoInfo: RepoInfo = RepoInfo()
    @Published var branches: [Branch] = []
    @Published var tags: [Tag] = []
    @Published var stashes: [Stash] = []
    @Published var workspaceCommands: [WorkspaceCommand] = []
    @Published var selectedSidebarItem: AnyHashable?
    @Published var selectedCommit: Commit?
    @Published var selectedFileChange: FileChange?
    @Published var diffContent: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var repositoryURL: URL? {
        didSet {
            if let url = repositoryURL {
                Task {
                    await loadRepositoryData(from: url)
                }
            }
        }
    }
    @Published var foundRepositories: [URL] = []
    @Published var isSearchingRepositories = false
    @Published var permissionError: String?
    @Published var isCloning = false
    @Published var cloneProgress: Double = 0.0
    @Published var cloneStatus: String = ""
    @Published var cloneURL: String = ""
    @Published var cloneDirectory: URL?
    @Published var isShowingCloneSheet = false
    @Published var isShowingImportSheet = false
    @Published var isAddingLocalRepo = false
    @Published var isShowingAddLocalSheet = false
    @Published var localRepoPath: URL?
    @Published var localRepoName: String = ""
    @Published var importProgress: ImportProgress?
    @Published var isImporting = false
    @Published var importStatus: String = ""
    @Published var selectedBranch: Branch? {
        didSet {
            if let branch = selectedBranch, let url = repositoryURL {
                loadCommits(for: branch, in: url)
            }
        }
    }
    @Published var currentBranch: Branch?
    @Published var branchCommits: [Commit] = []
    @Published var commitDetails: CommitDetails?
    @Published var clonedRepositories: [URL] = []
    @Published var importedRepositories: [URL] = []
    @Published var selectedRepository: URL?

    struct ImportProgress: Identifiable {
        let id = UUID()
        var current: Int
        var total: Int
        var status: String
    }

    struct CommitDetails {
        let hash: String
        let author: String
        let authorEmail: String
        let date: Date
        let message: String
        let changedFiles: [FileChange]
        let diffContent: String?
        let parentHashes: [String]
        let branchNames: [String]
    }

    private var cancellables = Set<AnyCancellable>()
     let gitService = GitService()

    init() {
        setupBindings()
        loadWorkspaceCommands()
        loadRepositoryList()
    }

    func isGitRepository(at: URL) async -> Bool  {
        return await gitService.isGitRepository(at: at)
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
        guard await gitService.isGitRepository(at: url) else {
            errorMessage = "Selected directory is not a Git repository"
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Load branches
        branches = await gitService.getBranches(in: url)

        // Set current branch
        if let currentBranchName = await gitService.getCurrentBranch(in: url) {
            currentBranch = branches.first { $0.name == currentBranchName }
            selectedBranch = currentBranch

            // Load commits for current branch
            if let branch = currentBranch {
                branchCommits = await gitService.getCommits(for: branch.name, in: url)
            }
        }

        // Load other repository data
        tags = await gitService.getTags(in: url)
        stashes = await gitService.getStashes(in: url)

        // Update repository info
        repoInfo = await gatherRepositoryInfo(from: url)
    }

    private func gatherRepositoryInfo(from url: URL) async -> RepoInfo {
        // Get repository name
        let name = url.lastPathComponent

        // Get current branch
        let currentBranch = await gitService.getCurrentBranch(in: url) ?? "main"

        // Get remote information
        let remotes = await gitService.getRemotes(in: url)

        return RepoInfo(
            name: name,
            currentBranch: currentBranch,
            remotes: remotes
        )
    }

    private func loadCommits(for branch: Branch, in url: URL) {
        Task {
            isLoading = true
            defer { isLoading = false }

            branchCommits = await gitService.getCommits(for: branch.name, in: url)
        }
    }

    // --- Bindings Setup ---
    private func setupBindings() {
        $selectedFileChange
            .dropFirst()
            .sink { [weak self] fileChange in
                guard let self = self,
                      let fileChange = fileChange,
                      let commit = self.selectedCommit,
                      let url = self.repositoryURL else { return }

                self.isLoading = true
                defer { self.isLoading = false }

                Task {
                    if let diff = await self.gitService.getDiff(for: commit.hash, file: fileChange.name, in: url) {
                        self.diffContent = diff
                    } else {
                        self.diffContent = """
                        diff --git a/\(fileChange.name) b/\(fileChange.name)
                        index 0000000..1234567
                        --- a/\(fileChange.name)
                        +++ b/\(fileChange.name)
                        @@ -0,0 +1,1 @@
                        +// Could not load diff for \(fileChange.name)
                        """
                    }
                }
            }
            .store(in: &cancellables)

        $selectedCommit
            .dropFirst()
            .sink { [weak self] commit in
                guard let self = self else { return }
                if commit == nil {
                    self.selectedFileChange = nil
                    self.diffContent = nil
                    self.commitDetails = nil
                } else if let commit = commit, let url = self.repositoryURL {
                    Task {
                        await self.loadCommitDetails(commit, in: url)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // --- Git Actions ---
    func performFetch() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        if let result = await gitService.runGitCommand("fetch", in: url) {
            if result.error.isEmpty {
                // Refresh repository data
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Fetch failed: \(result.error)"
            }
        } else {
            errorMessage = "Failed to execute fetch command"
        }
    }

    func performPull() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        if let result = await gitService.runGitCommand("pull", in: url) {
            if result.error.isEmpty {
                // Refresh repository data
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Pull failed: \(result.error)"
            }
        } else {
            errorMessage = "Failed to execute pull command"
        }
    }

    func performPush() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        if let result = await gitService.runGitCommand("push", in: url) {
            if !result.error.isEmpty {
                errorMessage = "Push failed: \(result.error)"
            }
        } else {
            errorMessage = "Failed to execute push command"
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
                foundRepositories = await gitService.findGitRepositories(in: directory)
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

    func cloneRepository(from url: String, to directory: URL) {
        guard !url.isEmpty else {
            errorMessage = "Please enter a repository URL"
            return
        }

        isCloning = true
        cloneProgress = 0.0
        cloneStatus = "Starting clone..."

        Task {
            do {
                let success = await gitService.cloneRepository(from: url, to: directory)

                if success {
                    let repoName = url.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? "repository"
                    let repoPath = directory.appendingPathComponent(repoName)
                    addClonedRepository(repoPath)
                    repositoryURL = repoPath
                    isShowingCloneSheet = false
                }
            } catch {
                errorMessage = "Clone failed: \(error.localizedDescription)"
            }

            isCloning = false
            cloneProgress = 0.0
            cloneStatus = ""
        }

        // Start progress monitoring
        Task {
            while isCloning {
                cloneProgress = await gitService.progress
                cloneStatus = await gitService.status
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    func importRepository(from url: URL) {
        Task {
            if await gitService.isGitRepository(at: url) {
                addImportedRepository(url)
                repositoryURL = url
                isShowingImportSheet = false
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Selected directory is not a Git repository"
            }
        }
    }

    func addLocalRepository(at url: URL) async {
        isImporting = true
        importProgress = ImportProgress(current: 0, total: 100, status: "Preparing repository...")

        do {
            // Validate Git repository
            importStatus = "Validating Git repository..."
            guard await gitService.isGitRepository(at: url) else {
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

        // Get full commit details
        let details = await gitService.getCommitDetails(for: commit.hash, in: url)
        commitDetails = details
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
}
