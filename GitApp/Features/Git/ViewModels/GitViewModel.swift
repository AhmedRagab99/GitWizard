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
    @Published var stagedChanges: [FileChange] = []
    @Published var unstagedChanges: [FileChange] = []

    struct ImportProgress: Identifiable {
        let id = UUID()
        var current: Int
        var total: Int
        var status: String
    }

    struct CommitDetails {
        let hash: String
        let authorName: String
        let authorEmail: String
        let date: Date
        let message: String
        let changedFiles: [FileChange]
        let diffContent: String?
        let parentHashes: [String]
        let branchNames: [String]
    }

    private var cancellables = Set<AnyCancellable>()
    private let gitService = GitService()

    init() {
        setupBindings()
        loadWorkspaceCommands()
        loadRepositoryList()
    }

    func isGitRepository(at: URL) async -> Bool {
        do {
            return try await gitService.isGitRepository(at: at)
        } catch {
            errorMessage = "Error checking repository: \(error.localizedDescription)"
            return false
        }
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
            guard try await gitService.isGitRepository(at: url) else {
                errorMessage = "Selected directory is not a Git repository"
                return
            }

            isLoading = true
            defer { isLoading = false }

            // Load branches
            branches = try await gitService.getBranches(in: url)

            // Set current branch
            if let currentBranchName = try await gitService.getCurrentBranch(in: url) {
                currentBranch = branches.first { $0.name == currentBranchName }
                selectedBranch = currentBranch

                // Load commits for current branch
                if let branch = currentBranch {
                    branchCommits = try await gitService.getCommits(for: branch.name, in: url)
                }
            }

            // Load other repository data
            tags = try await gitService.getTags(in: url)
            stashes = try await gitService.getStashes(in: url)

            // Update repository info
            repoInfo = await gatherRepositoryInfo(from: url)
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

                branchCommits = try await gitService.getCommits(for: branch.name, in: url)
            } catch {
                errorMessage = "Error loading commits: \(error.localizedDescription)"
            }
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
                    do {
                        if let diff = try await self.gitService.getDiff(for: commit.hash, file: fileChange.name, in: url) {
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
                    } catch {
                        self.errorMessage = "Error loading diff: \(error.localizedDescription)"
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

        do {
            let result = try await gitService.runGitCommand("fetch", in: url)
            if result.error.isEmpty {
                // Refresh repository data
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Fetch failed: \(result.error)"
            }
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
            let result = try await gitService.runGitCommand("pull", in: url)
            if result.error.isEmpty {
                // Refresh repository data
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Pull failed: \(result.error)"
            }
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
            let result = try await gitService.runGitCommand("push", in: url)
            if !result.error.isEmpty {
                errorMessage = "Push failed: \(result.error)"
            }
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
                let success = try await gitService.cloneRepository(from: url, to: directory)

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
            if let details = try await gitService.getCommitDetails(for: commit.hash, in: url) {
                commitDetails = details
            } else {
                errorMessage = "Could not load commit details"
            }
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

        isLoading = true
        defer { isLoading = false }

        do {
            // Get staged changes
            let stagedResult = try await gitService.runGitCommand("diff", "--cached", "--name-status", in: url)
            let stagedChanges = parseFileChanges(from: stagedResult.output)

            // Load line changes for each staged file
            var updatedStagedChanges = stagedChanges
            for i in updatedStagedChanges.indices {
                let fileChange = updatedStagedChanges[i]
                let lineChanges = try await loadLineChanges(for: fileChange.path, in: url)
                updatedStagedChanges[i].stagedChanges = lineChanges.staged
                updatedStagedChanges[i].unstagedChanges = lineChanges.unstaged
            }
            self.stagedChanges = updatedStagedChanges

            // Get unstaged changes
            let unstagedResult = try await gitService.runGitCommand("diff", "--name-status", in: url)
            let unstagedChanges = parseFileChanges(from: unstagedResult.output)

            // Load line changes for each unstaged file
            var updatedUnstagedChanges = unstagedChanges
            for i in updatedUnstagedChanges.indices {
                let fileChange = updatedUnstagedChanges[i]
                let lineChanges = try await loadLineChanges(for: fileChange.path, in: url)
                updatedUnstagedChanges[i].stagedChanges = lineChanges.staged
                updatedUnstagedChanges[i].unstagedChanges = lineChanges.unstaged
            }
            self.unstagedChanges = updatedUnstagedChanges
        } catch {
            errorMessage = "Error loading changes: \(error.localizedDescription)"
        }
    }
    
  
    private func loadLineChanges(for filePath: String, in url: URL) async throws -> (staged: [LineChange], unstaged: [LineChange]) {
        // Get staged changes
        let stagedResult = try await gitService.runGitCommand("diff", "--cached", "-U0", filePath, in: url)
        let stagedChanges = parseLineChanges(from: stagedResult.output)

        // Get unstaged changes
        let unstagedResult = try await gitService.runGitCommand("diff", "-U0", filePath, in: url)
        let unstagedChanges = parseLineChanges(from: unstagedResult.output)

        return (staged: stagedChanges, unstaged: unstagedChanges)
    }

    private func parseFileChanges(from output: String) -> [FileChange] {
        output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line in
                let components = line.components(separatedBy: .whitespaces)
                guard components.count >= 2 else { return nil }

                let status = components[0]
                let path = components[1...].joined(separator: " ")

                return FileChange(
                    id: UUID(),
                    name: (path as NSString).lastPathComponent,
                    status: status,
                    path: path,
                    stagedChanges: [],
                    unstagedChanges: []
                )
            }
            .compactMap { $0 }
    }

    private func parseLineChanges(from output: String) -> [LineChange] {
        var changes: [LineChange] = []
        var lineNumber = 0

        output.components(separatedBy: .newlines)
            .forEach { line in
                if line.hasPrefix("@@") {
                    // Parse line number from diff header
                    if let match = line.range(of: #"\+(\d+)"#) {
                        lineNumber = Int(line[match].dropFirst()) ?? 0
                    }
                } else if line.hasPrefix("+") {
                    changes.append(LineChange(
                        id: UUID(),
                        lineNumber: lineNumber,
                        content: String(line.dropFirst()),
                        type: .added
                    ))
                    lineNumber += 1
                } else if line.hasPrefix("-") {
                    changes.append(LineChange(
                        id: UUID(),
                        lineNumber: lineNumber,
                        content: String(line.dropFirst()),
                        type: .removed
                    ))
                } else {
                    lineNumber += 1
                }
            }

        return changes
    }

    func stageLines(_ lines: Set<UUID>, in file: FileChange) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                for line in lines {
                    if let change = file.lineChanges.first(where: { $0.id == line }) {
                        try await gitService.runGitCommand("add", "-p", file.path, in: url)
                    }
                }
                await loadChanges()
            } catch {
                errorMessage = "Error staging lines: \(error.localizedDescription)"
            }
        }
    }

    func unstageLines(_ lines: Set<UUID>, in file: FileChange) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                for line in lines {
                    if let change = file.lineChanges.first(where: { $0.id == line }) {
                        try await gitService.runGitCommand("reset", "-p", file.path, in: url)
                    }
                }
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging lines: \(error.localizedDescription)"
            }
        }
    }

    func resetLines(_ lines: Set<UUID>, in file: FileChange) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                for line in lines {
                    if let change = file.lineChanges.first(where: { $0.id == line }) {
                        try await gitService.runGitCommand("checkout", "--", file.path, in: url)
                    }
                }
                await loadChanges()
            } catch {
                errorMessage = "Error resetting lines: \(error.localizedDescription)"
            }
        }
    }

    func stageAllChanges() {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.runGitCommand("add", ".", in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error staging all changes: \(error.localizedDescription)"
            }
        }
    }

    func unstageAllChanges() {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.runGitCommand("reset", ".", in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging all changes: \(error.localizedDescription)"
            }
        }
    }

    func commitChanges(message: String) async {
        guard let url = repositoryURL else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await gitService.runGitCommand("commit", "-m", message, in: url)
            if result.error.isEmpty {
                await loadChanges()
                await loadRepositoryData(from: url)
            } else {
                errorMessage = "Commit failed: \(result.error)"
            }
        } catch {
            errorMessage = "Commit failed: \(error.localizedDescription)"
        }
    }

    private func parseCommits(from output: String) -> [Commit] {
        output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line in
                let components = line.components(separatedBy: "|")
                guard components.count >= 6 else { return nil }

                let hash = components[0].trimmingCharacters(in: .whitespaces)
                let authorName = components[1].trimmingCharacters(in: .whitespaces)
                let authorEmail = components[2].trimmingCharacters(in: .whitespaces)
                let dateString = components[3].trimmingCharacters(in: .whitespaces)
                let message = components[4].trimmingCharacters(in: .whitespaces)
                let parentHashes = components[5].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                // Determine commit type based on message and parent hashes
                let commitType = determineCommitType(message: message, parentHashes: parentHashes)

                // Generate avatar URL based on email (using Gravatar)
                let emailHash = authorEmail.lowercased().md5Hash
                let authorAvatar = "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=40"

                // Parse date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                let date = dateFormatter.date(from: dateString) ?? Date()

                return Commit(
                    id: UUID(),
                    hash: hash,
                    authorName: authorName,
                    authorEmail: authorEmail,
                    date: date,
                    message: message,
                    parentHashes: parentHashes,
                    branchNames: [],
                    commitType: commitType,
                    authorAvatar: authorAvatar
                )
            }
            .compactMap { $0 }
    }

    private func determineCommitType(message: String, parentHashes: [String]) -> Commit.CommitType {
        let lowercasedMessage = message.lowercased()

        if parentHashes.count > 1 {
            return .merge
        } else if lowercasedMessage.contains("rebase") {
            return .rebase
        } else if lowercasedMessage.contains("cherry-pick") {
            return .cherryPick
        } else if lowercasedMessage.contains("revert") {
            return .revert
        } else {
            return .normal
        }
    }
}
