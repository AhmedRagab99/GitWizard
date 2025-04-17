import SwiftUI

// --- Placeholder Data Models ---

struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    var currentBranch: String = "main"
    var remotes: [(name: String, url: String)] = []
    // Add other repo details if needed
}



struct Commit: Identifiable, Hashable {
    let id = UUID()
    var hash: String
    var message: String
    var author: String
    var authorEmail: String
    var authorAvatar: String // URL or system image name
    var date: Date
    var changedFiles: [FileChange] = []
    var parentHashes: [String] = []
    var branchNames: [String] = []
    var commitType: CommitType = .normal
    var diffContent: String? // Store actual diff content
}

struct FileChange: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var status: String // e.g., "Modified", "Added", "Deleted"
}

struct WorkspaceCommand: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String // SF Symbol name
}

struct Tag: Identifiable, Hashable {
    let id = UUID()
    var name: String
}

struct Stash: Identifiable, Hashable {
    let id = UUID()
    var description: String
    var date: Date
}

enum CommitType: String, Hashable {
    case normal
    case merge
    case rebase
    case cherryPick
    case revert
}

// --- Main View Structure ---

struct RepositorySelectionView: View {
    @ObservedObject var viewModel: GitViewModel
    @Binding var isShowingFilePicker: Bool
    @Binding var selectedDirectory: URL?

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isSearchingRepositories {
                ProgressView("Searching for repositories...")
            } else if !viewModel.foundRepositories.isEmpty {
                List(viewModel.foundRepositories, id: \.self) { url in
                    Button {
                        viewModel.selectRepository(url)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .font(.headline)
                            Text(url.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button("Search Another Directory") {
                    isShowingFilePicker = true
                }
            } else {
                VStack(spacing: 16) {
                    Text("Welcome to Git Client")
                        .font(.title)

                    Text("Choose a directory to find Git repositories")
                        .foregroundColor(.secondary)

                    Button("Choose Directory") {
                        isShowingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}

struct GitClientView: View {
    @StateObject private var viewModel = GitViewModel()
    @State private var isShowingFilePicker = false
    @State private var selectedDirectory: URL?

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } content: {
            if let url = viewModel.repositoryURL {
                HistoryView(viewModel: viewModel)
            } else {
                RepositorySelectionView(
                    viewModel: viewModel,
                    isShowingFilePicker: $isShowingFilePicker,
                    selectedDirectory: $selectedDirectory
                )
            }
        } detail: {
            if let commit = viewModel.selectedCommit {
                CommitDetailView(commit: commit, details: viewModel.commitDetails)
            } else {
                Text("Select a commit to view details")
                    .foregroundColor(.secondary)
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.directory],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDirectory = url
                    viewModel.searchForRepositories(in: url)
                }
            case .failure(let error):
                viewModel.errorMessage = "Failed to select directory: \(error.localizedDescription)"
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// --- Sidebar View ---
struct SidebarView: View {
    @ObservedObject var viewModel: GitViewModel

    var body: some View {
        List {
            Section("Repository") {
                Text(viewModel.repoInfo.name)
                Text("Branch: \(viewModel.repoInfo.currentBranch)")
            }

            Section("Branches") {
                ForEach(viewModel.branches) { branch in
                    HStack {
                        Text(branch.name)
                        if branch.isCurrent {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedBranch = branch
                    }
                }
            }

            Section("Tags") {
                ForEach(viewModel.tags) { tag in
                    Text(tag.name)
                }
            }

            Section("Stashes") {
                ForEach(viewModel.stashes) { stash in
                    Text(stash.description)
                }
            }

            Section("Workspace") {
                ForEach(viewModel.workspaceCommands) { command in
                    Button {
                        Task {
                            switch command.name {
                            case "Fetch":
                                await viewModel.performFetch()
                            case "Pull":
                                await viewModel.performPull()
                            case "Push":
                                await viewModel.performPush()
                            case "Commit":
                                await viewModel.performCommit()
                            default:
                                break
                            }
                        }
                    } label: {
                        Label(command.name, systemImage: command.icon)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// --- Commit Graph Row View ---
struct CommitGraphRowView: View {
    let commit: Commit

    var body: some View {
        HStack(spacing: 8) {
            // Commit graph visualization
            CommitGraphVisualization(commit: commit)
                .frame(width: 100)

            // Commit details
            VStack(alignment: .leading, spacing: 4) {
                Text(commit.message)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(commit.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(commit.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !commit.changedFiles.isEmpty {
                    Text("\(commit.changedFiles.count) files changed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Branch indicators
            if !commit.branchNames.isEmpty {
                VStack(alignment: .trailing) {
                    ForEach(commit.branchNames, id: \.self) { branch in
                        Text(branch)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}

struct CommitGraphVisualization: View {
    let commit: Commit

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width

            ZStack {
                // Parent connections
                ForEach(commit.parentHashes, id: \.self) { parent in
                    Path { path in
                        let x = width / 2
                        path.move(to: CGPoint(x: x, y: height))
                        path.addLine(to: CGPoint(x: x, y: height / 2))
                    }
                    .stroke(Color.gray, lineWidth: 1)
                }

                // Commit node
                Circle()
                    .fill(commit.commitType == .merge ? Color.purple : Color.blue)
                    .frame(width: 12, height: 12)
                    .position(x: width / 2, y: height / 2)
            }
        }
    }
}

// --- History View (Main Pane) ---
struct HistoryView: View {
    @ObservedObject var viewModel: GitViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.branchCommits) { commit in
                    CommitGraphRowView(commit: commit)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedCommit = commit
                        }
                }
            }
        }
    }
}

// --- Commit Detail View ---
struct CommitDetailView: View {
    let commit: Commit
    let details: GitViewModel.CommitDetails?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Commit header
                VStack(alignment: .leading, spacing: 8) {
                    Text(commit.message)
                        .font(.title2)
                        .bold()

                    HStack {
                        Text(commit.author)
                        Text("<\(commit.authorEmail)>")
                            .foregroundColor(.secondary)
                    }

                    Text(commit.date.formatted())
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)

                // Changed files
                if let details = details {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Changed Files")
                            .font(.headline)

                        ForEach(details.changedFiles, id: \.name) { file in
                            HStack {
                                Text(file.name)
                                Spacer()
                                Text(file.status)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)

                    // Diff content
                    if let diff = details.diffContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Changes")
                                .font(.headline)

                            Text(diff)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Add sample data for testing
extension Commit {
    static var sampleCommits: [Commit] {
        [
            Commit(
                hash: "a1b2c3d",
                message: "Initial commit",
                author: "John Doe",
                authorEmail: "john@example.com",
                authorAvatar: "person.crop.circle.fill",
                date: Date().addingTimeInterval(-86400 * 7),
                changedFiles: [
                    FileChange(name: "README.md", status: "Added"),
                    FileChange(name: "GitClientView.swift", status: "Added")
                ],
                parentHashes: [],
                branchNames: ["main"],
                commitType: .normal,
                diffContent: """
                diff --git a/README.md b/README.md
                new file mode 100644
                index 0000000..e69de29
                --- /dev/null
                +++ b/README.md
                """
            ),
            Commit(
                hash: "b2c3d4e",
                message: "Add user authentication",
                author: "Jane Smith",
                authorEmail: "jane@example.com",
                authorAvatar: "person.crop.circle.fill",
                date: Date().addingTimeInterval(-86400 * 6),
                changedFiles: [
                    FileChange(name: "AuthService.swift", status: "Added"),
                    FileChange(name: "UserModel.swift", status: "Added")
                ],
                parentHashes: ["a1b2c3d"],
                branchNames: ["feature/auth"],
                commitType: .normal,
                diffContent: """
                diff --git a/AuthService.swift b/AuthService.swift
                new file mode 100644
                index 0000000..1234567
                --- /dev/null
                +++ b/AuthService.swift
                @@ -0,0 +1,10 @@
                +class AuthService {
                +    func login(username: String, password: String) -> Bool {
                +        // Implementation
                +        return true
                +    }
                +}
                """
            ),
            Commit(
                hash: "c3d4e5f",
                message: "Merge feature/auth into main",
                author: "John Doe",
                authorEmail: "john@example.com",
                authorAvatar: "person.crop.circle.fill",
                date: Date().addingTimeInterval(-86400 * 5),
                changedFiles: [
                    FileChange(name: "AuthService.swift", status: "Modified"),
                    FileChange(name: "UserModel.swift", status: "Modified")
                ],
                parentHashes: ["a1b2c3d", "b2c3d4e"],
                branchNames: ["main"],
                commitType: .merge,
                diffContent: """
                diff --git a/AuthService.swift b/AuthService.swift
                index 1234567..2345678
                --- a/AuthService.swift
                +++ b/AuthService.swift
                @@ -1,5 +1,6 @@
                 class AuthService {
                -    func login(username: String, password: String) -> Bool {
                +    func login(username: String, password: String) async throws -> Bool {
                +        // Updated implementation with async/await
                         return true
                     }
                +}
                """
            ),
            Commit(
                hash: "d4e5f6g",
                message: "Add commit graph visualization",
                author: "Alice Johnson",
                authorEmail: "alice@example.com",
                authorAvatar: "person.crop.circle.fill",
                date: Date().addingTimeInterval(-86400 * 4),
                changedFiles: [
                    FileChange(name: "CommitGraphView.swift", status: "Added"),
                    FileChange(name: "GitClientView.swift", status: "Modified")
                ],
                parentHashes: ["c3d4e5f"],
                branchNames: ["feature/graph"],
                commitType: .normal,
                diffContent: """
                diff --git a/CommitGraphView.swift b/CommitGraphView.swift
                new file mode 100644
                index 0000000..3456789
                --- /dev/null
                +++ b/CommitGraphView.swift
                @@ -0,0 +1,20 @@
                +struct CommitGraphView: View {
                +    let commits: [Commit]
                +
                +    var body: some View {
                +        Canvas { context, size in
                +            // Implementation
                +        }
                +    }
                +}
                """
            ),
            Commit(
                hash: "e5f6g7h",
                message: "Rebase feature/graph onto main",
                author: "Alice Johnson",
                authorEmail: "alice@example.com",
                authorAvatar: "person.crop.circle.fill",
                date: Date().addingTimeInterval(-86400 * 3),
                changedFiles: [
                    FileChange(name: "CommitGraphView.swift", status: "Modified"),
                    FileChange(name: "GitClientView.swift", status: "Modified")
                ],
                parentHashes: ["c3d4e5f"],
                branchNames: ["feature/graph"],
                commitType: .rebase,
                diffContent: """
                diff --git a/CommitGraphView.swift b/CommitGraphView.swift
                index 3456789..4567890
                --- a/CommitGraphView.swift
                +++ b/CommitGraphView.swift
                @@ -1,5 +1,6 @@
                 struct CommitGraphView: View {
                -    let commits: [Commit]
                +    @State private var selectedCommit: Commit?
                +    let commits: [Commit]

                     var body: some View {
                         Canvas { context, size in
                """
            )
        ]
    }
}

struct CloneRepositoryView: View {
    @ObservedObject var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Repository URL") {
                    TextField("https://github.com/username/repo.git", text: $viewModel.cloneURL)
                        .textContentType(.URL)
                }

                Section("Clone Location") {
                    if let directory = viewModel.cloneDirectory {
                        Text(directory.path)
                            .foregroundStyle(.secondary)
                    }

                    Button("Choose Directory") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false

                        if panel.runModal() == .OK, let url = panel.url {
                            viewModel.cloneDirectory = url
                        }
                    }
                }

                if viewModel.isCloning {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: viewModel.cloneProgress)
                                .progressViewStyle(.linear)
                            Text(viewModel.cloneStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Clone Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        if let directory = viewModel.cloneDirectory {
                            viewModel.cloneRepository(from: viewModel.cloneURL, to: directory)
                        } else {
                            viewModel.errorMessage = "Please select a directory to clone into"
                        }
                    }
                    .disabled(viewModel.cloneURL.isEmpty || viewModel.cloneDirectory == nil || viewModel.isCloning)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }
}

struct ImportRepositoryView: View {
    @ObservedObject var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?

    var body: some View {
        NavigationStack {
            VStack {
                if let url = selectedURL {
                    Text(url.path)
                        .foregroundStyle(.secondary)
                        .padding()
                }

                Button("Choose Repository") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false

                    if panel.runModal() == .OK {
                        selectedURL = panel.url
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Import Repository")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        if let url = selectedURL {
                            viewModel.importRepository(from: url)
                        } else {
                            viewModel.errorMessage = "Please select a Git repository"
                        }
                    }
                    .disabled(selectedURL == nil)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }
}

struct AddLocalRepositoryView: View {
    @ObservedObject var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?
    @State private var isGitRepo: Bool = false
    @State private var branchInfo: String?
    @State private var remoteInfo: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let url = selectedURL {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                Text(url.path)
                                    .foregroundStyle(.secondary)
                            }

                            if isGitRepo {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Valid Git Repository", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)

                                    if let branch = branchInfo {
                                        HStack {
                                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                                .foregroundStyle(.secondary)
                                            Text("Current Branch: \(branch)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !remoteInfo.isEmpty {
                                        Text("Remotes:")
                                            .font(.headline)
                                        ForEach(remoteInfo, id: \.self) { remote in
                                            HStack {
                                                Image(systemName: "arrow.triangle.branch")
                                                    .foregroundStyle(.secondary)
                                                Text(remote)
                                                    .font(.system(.body, design: .monospaced))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            } else {
                                Label("Not a Git Repository", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Button("Choose Repository") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false

                            if panel.runModal() == .OK {
                                selectedURL = panel.url
                                updateRepositoryInfo()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Local Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let url = selectedURL {
                            Task {
                                await viewModel.addLocalRepository(at: url)
                            }
                        }
                    }
                    .disabled(selectedURL == nil || viewModel.isImporting || !isGitRepo)
                }
            }
            .overlay {
                if viewModel.isImporting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        if let progress = viewModel.importProgress {
                            VStack(spacing: 8) {
                                ProgressView(value: Double(progress.current), total: Double(progress.total))
                                    .progressViewStyle(.linear)

                                Text(progress.status)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 200)
                        }

                        Text(viewModel.importStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private func updateRepositoryInfo() {
        guard let url = selectedURL else { return }

        Task {
            // Check if it's a Git repository
            isGitRepo = await viewModel.isGitRepository(at: url)

            if isGitRepo {
                // Get current branch
                if let branchResult = await viewModel.gitService.runGitCommand("rev-parse", "--abbrev-ref", "HEAD", in: url) {
                    branchInfo = branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
                }

                // Get remote information
                if let remoteResult = await viewModel.gitService.runGitCommand("remote", "-v", in: url) {
                    remoteInfo = remoteResult.output.components(separatedBy: "\n")
                        .filter { !$0.isEmpty }
                }
            } else {
                branchInfo = nil
                remoteInfo = []
            }
        }
    }
}

// --- Preview ---
#Preview {
    GitClientView()
}
