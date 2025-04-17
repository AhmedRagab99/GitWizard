import SwiftUI
import Combine

// --- Git View Model ---

@MainActor // Ensure UI updates happen on the main thread
class GitViewModel: ObservableObject {
    // --- Published Properties (State) ---
    @Published var repoInfo: RepoInfo = RepoInfo()
    @Published var branches: [Branch] = []
    @Published var tags: [Tag] = []
    @Published var stashes: [Stash] = []
    @Published var commits: [Commit] = []
    @Published var workspaceCommands: [WorkspaceCommand] = []

    @Published var selectedSidebarItem: AnyHashable?
    @Published var selectedCommit: Commit?
    @Published var selectedFileChange: FileChange?
    @Published var diffContent: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // --- Initializer & Data Loading ---
    init() {
        loadPlaceholderData()
        setupBindings()
    }

    // --- Placeholder Data Loading ---
    private func loadPlaceholderData() {
        commits = Commit.sampleCommits

        let allBranchNames = Set(commits.flatMap { $0.branchNames })
        branches = allBranchNames.map { Branch(name: $0) }

        tags = [
            Tag(name: "v1.0.0"),
            Tag(name: "v1.1.0")
        ]

        stashes = [
            Stash(description: "WIP: Authentication improvements", date: Date().addingTimeInterval(-3600)),
            Stash(description: "WIP: Graph visualization", date: Date().addingTimeInterval(-7200))
        ]

        workspaceCommands = [
            WorkspaceCommand(name: "Fetch", icon: "arrow.triangle.2.circlepath"),
            WorkspaceCommand(name: "Pull", icon: "arrow.down.circle"),
            WorkspaceCommand(name: "Push", icon: "arrow.up.circle"),
            WorkspaceCommand(name: "Commit", icon: "checkmark.circle")
        ]
    }

    // --- Bindings Setup ---
    private func setupBindings() {
        $selectedFileChange
            .dropFirst()
            .sink { [weak self] fileChange in
                guard let self = self else { return }
                if let fileChange = fileChange {
                    self.loadDiff(for: fileChange)
                } else {
                    self.diffContent = nil
                }
            }
            .store(in: &cancellables)

        $selectedCommit
            .dropFirst()
            .sink { [weak self] commit in
                guard let self = self else { return }
                if commit == nil {
                    self.selectedFileChange = nil
                }
            }
            .store(in: &cancellables)
    }

    // --- Diff Loading ---
    private func loadDiff(for fileChange: FileChange) {
        guard let commit = selectedCommit else { return }

        isLoading = true
        defer { isLoading = false }

        if let diff = commit.diffContent {
            diffContent = diff
        } else {
            diffContent = """
            diff --git a/\(fileChange.name) b/\(fileChange.name)
            index 0000000..1234567
            --- a/\(fileChange.name)
            +++ b/\(fileChange.name)
            @@ -0,0 +1,1 @@
            +// Sample diff content for \(fileChange.name)
            """
        }
    }

    // --- Git Actions ---
    func performFetch() {
        isLoading = true
        defer { isLoading = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.errorMessage = "Fetch not implemented yet"
        }
    }

    func performPull() {
        isLoading = true
        defer { isLoading = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.errorMessage = "Pull not implemented yet"
        }
    }

    func performPush() {
        isLoading = true
        defer { isLoading = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.errorMessage = "Push not implemented yet"
        }
    }

    func performCommit() {
        isLoading = true
        defer { isLoading = false }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.errorMessage = "Commit not implemented yet"
        }
    }
}
