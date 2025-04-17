import SwiftUI

// --- Placeholder Data Models ---

struct RepoInfo: Identifiable {
    let id = UUID()
    var name: String = "MyExampleRepo"
    // Add other repo details if needed
}

struct Branch: Identifiable, Hashable {
    let id = UUID()
    var name: String
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

struct GitClientView: View {
    // Use the ViewModel as the source of truth
    @StateObject private var viewModel = GitViewModel()

    var body: some View {
        NavigationSplitView {
            // Pass necessary data/bindings from ViewModel
            SidebarView(
                repoName: viewModel.repoInfo.name,
                branches: viewModel.branches,
                workspaceCommands: viewModel.workspaceCommands,
                tags: viewModel.tags,
                stashes: viewModel.stashes,
                selection: $viewModel.selectedSidebarItem,
                // Pass action closures
                onFetch: viewModel.performFetch,
                onPull: viewModel.performPull,
                onPush: viewModel.performPush,
                onCommit: viewModel.performCommit
            )
        } content: {
            HistoryView(
                commits: viewModel.commits,
                selectedCommit: $viewModel.selectedCommit
            )
        } detail: {
            CommitDetailView(
                commit: viewModel.selectedCommit,
                selectedFile: $viewModel.selectedFileChange, // Bind selected file
                diffContent: viewModel.diffContent,      // Pass diff content
                isLoadingDiff: viewModel.isLoading       // Pass loading state
            )
        }
        .navigationSplitViewStyle(.balanced)
        // Display global errors from the ViewModel
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}

// --- Sidebar View ---
struct SidebarView: View {
    // Receive data and bindings from parent/ViewModel
    let repoName: String
    let branches: [Branch]
    let workspaceCommands: [WorkspaceCommand]
    let tags: [Tag]
    let stashes: [Stash]
    @Binding var selection: AnyHashable?

    // Actions passed from ViewModel
    let onFetch: () -> Void
    let onPull: () -> Void
    let onPush: () -> Void
    let onCommit: () -> Void

    var body: some View {
        List(selection: $selection) {
            Section("Workspace") {
                // Convert Labels to Buttons triggering ViewModel actions
                ForEach(workspaceCommands) { command in
                    Button {
                        // Call the appropriate action based on command name
                        switch command.name {
                        case "Fetch": onFetch()
                        case "Pull": onPull()
                        case "Push": onPush()
                        case "Commit": onCommit()
                        default: print("Unknown command: \(command.name)")
                        }
                    } label: {
                        Label(command.name, systemImage: command.icon)
                    }
                    .buttonStyle(.plain) // Use plain style for list buttons
                    .tag(command) // Keep tag for potential selection logic if needed
                }
            }

            Section("Branches") {
                ForEach(branches) { branch in
                    Label(branch.name, systemImage: "point.3.connected.trianglepath.dotted").tag(branch)
                }
            }

            Section("Tags") {
                 ForEach(tags) { tag in
                    Label(tag.name, systemImage: "tag.fill").tag(tag)
                }
            }

             Section("Stashes") {
                 ForEach(stashes) { stash in
                    VStack(alignment: .leading) {
                         Text(stash.description).font(.headline)
                         Text(stash.date, style: .relative) + Text(" ago")
                    }
                    .tag(stash)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(repoName)
    }
}

// --- Commit Graph Row View ---
struct CommitGraphRowView: View {
    let commit: Commit
    let index: Int // Index in the displayed list (newest first)
    let allCommits: [Commit] // Full list for context
    let isSelected: Bool
    let graphWidth: CGFloat = 60 // Increased width for branches/labels
    let nodeSize: CGFloat = 8
    let laneOffset: CGFloat = 12 // Horizontal offset for simple branching

    // Precompute parent/child indices for drawing
    private var parentIndices: [Int] {
        commit.parentHashes.compactMap { pHash in
            allCommits.firstIndex { $0.hash == pHash }
        }
    }

    private var childIndices: [Int] {
        allCommits.indices.filter { allCommits[$0].parentHashes.contains(commit.hash) }
    }

    private func commitTypeIcon(_ type: CommitType) -> String {
        switch type {
        case .normal: return "circle.fill"
        case .merge: return "arrow.triangle.merge"
        case .rebase: return "arrow.triangle.branch"
        case .cherryPick: return "arrow.triangle.2.circlepath"
        case .revert: return "arrow.uturn.backward"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // --- Graph Canvas ---
            Canvas { context, size in
                let nodeCenter = CGPoint(x: size.width / 2, y: size.height / 2)
                let isMergeCommit = commit.parentHashes.count > 1

                // Simplified lane calculation (just use index 0 for main line, offset for others)
                // A real implementation needs a proper layout algorithm.
                func xPos(for lane: Int) -> CGFloat {
                    return nodeCenter.x - (laneOffset * CGFloat(lane))
                }

                // --- Draw Lines to Parents ---
                for (parentIndexOffset, parentListIndex) in parentIndices.enumerated() {
                    let parentRowDiff = parentListIndex - index
                    let startPoint = CGPoint(x: xPos(for: parentIndexOffset), y: nodeCenter.y + nodeSize / 2)
                    var endPoint = CGPoint(x: xPos(for: 0), y: size.height * CGFloat(parentRowDiff) + size.height / 2) // Default to parent's main lane

                    // Simple curve/diagonal for merges showing in adjacent row
                    if parentRowDiff == 1 {
                         if isMergeCommit {
                            endPoint.x = xPos(for: parentIndexOffset) // Keep lane for direct parent merge
                        }
                        let controlPoint1 = CGPoint(x: startPoint.x, y: startPoint.y + size.height / 3)
                        let controlPoint2 = CGPoint(x: endPoint.x, y: endPoint.y - size.height / 3)

                        var path = Path()
                        path.move(to: startPoint)
                        path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
                        context.stroke(path, with: .color(.gray), lineWidth: 1.5)

                    } else if parentRowDiff > 1 {
                        // For non-adjacent parents, just draw a straight line down (simplified)
                         var path = Path()
                         path.move(to: startPoint)
                         path.addLine(to: CGPoint(x: startPoint.x, y: size.height))
                         context.stroke(path, with: .color(.gray.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    }
                }

                // --- Draw Lines to Children ---
                // Similar logic to parents, drawing upwards
                for (childIndexOffset, childListIndex) in childIndices.enumerated() {
                    let childRowDiff = childListIndex - index // Should be negative
                    let startPoint = CGPoint(x: xPos(for: 0), y: nodeCenter.y - nodeSize / 2)
                    var endPoint = CGPoint(x: xPos(for: childIndexOffset), y: size.height * CGFloat(childRowDiff) + size.height/2)

                    if childRowDiff == -1 { // Child is directly above
                        let controlPoint1 = CGPoint(x: startPoint.x, y: startPoint.y - size.height / 3)
                        let controlPoint2 = CGPoint(x: endPoint.x, y: endPoint.y + size.height / 3)

                        var path = Path()
                        path.move(to: startPoint)
                        path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
                        context.stroke(path, with: .color(.gray), lineWidth: 1.5)
                    } else if childRowDiff < -1 {
                        // For non-adjacent children, just draw line up (simplified)
                        var path = Path()
                        path.move(to: startPoint)
                        path.addLine(to: CGPoint(x: startPoint.x, y: 0))
                        context.stroke(path, with: .color(.gray.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    }
                }

                // --- Draw Commit Node ---
                let nodeCircle = Path(ellipseIn: CGRect(x: xPos(for: 0) - nodeSize / 2,
                                                           y: nodeCenter.y - nodeSize / 2,
                                                           width: nodeSize,
                                                           height: nodeSize))
                // Use different color/stroke for merge commits?
                context.fill(nodeCircle, with: .color(isMergeCommit ? .purple : .blue))
                context.stroke(nodeCircle, with: .color(.primary), lineWidth: 1)

            }
            .frame(width: graphWidth)

            // --- Commit Details & Branch Labels ---
            VStack(alignment: .leading, spacing: 4) {
                // Branch Labels and Commit Type
                HStack {
                    if !commit.branchNames.isEmpty {
                        ForEach(commit.branchNames, id: \.self) { branchName in
                            Text(branchName)
                                .font(.caption.bold())
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: commitTypeIcon(commit.commitType))
                        .foregroundStyle(commit.commitType == .normal ? .blue : .purple)
                        .help(commit.commitType.rawValue.capitalized)
                }
                .padding(.bottom, 2)

                Text(commit.message).font(.headline).lineLimit(1)
                HStack(spacing: 8) {
                    Image(systemName: commit.authorAvatar)
                        .foregroundStyle(.secondary)
                    Text(commit.author)
                    Text(commit.date, style: .relative)
                    Spacer()
                    Text(commit.hash.prefix(7))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)

            Spacer() // Pushes content to the left
        }
        .padding(.vertical, 8) // Increased padding
        .padding(.horizontal, 10)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle()) // Make the whole row tappable
    }
}

// --- History View (Main Pane) ---
struct HistoryView: View {
    // Receive data/bindings from ViewModel
    let commits: [Commit]
    @Binding var selectedCommit: Commit?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(commits.enumerated()), id: \.element.id) { index, commit in
                    CommitGraphRowView(commit: commit, index: index, allCommits: commits, isSelected: commit == selectedCommit)
                        .onTapGesture {
                            selectedCommit = commit
                        }
                    Divider().padding(.leading, 60 + 8)
                }
            }
        }
        .navigationTitle("History")
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// --- Diff View (Placeholder) ---
struct DiffView: View {
    let diffText: String?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Diff")
                .font(.headline)
                .padding(.bottom, 2)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let diffText = diffText {
                ScrollView(.vertical) {
                    Text(diffText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor).opacity(0.7))
                        .cornerRadius(6)
                        .textSelection(.enabled)
                }
            } else {
                Text("Select a changed file to view the diff.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.top, 10)
    }
}

// --- Commit Detail View ---
struct CommitDetailView: View {
    // Receive data/bindings from ViewModel
    let commit: Commit?
    @Binding var selectedFile: FileChange?
    let diffContent: String?
    let isLoadingDiff: Bool

    // Helper for file status icon and color
    private func fileStatusIcon(_ status: String) -> (String, Color) {
        switch status {
        case "Added":
            return ("plus.circle.fill", .green)
        case "Modified":
            return ("pencil.circle.fill", .orange)
        case "Deleted":
            return ("minus.circle.fill", .red)
        default:
            return ("questionmark.circle.fill", .gray)
        }
    }

    @ViewBuilder
    private func fileStatusIconView(_ status: String) -> some View {
        let (iconName, color) = fileStatusIcon(status)
        Image(systemName: iconName)
            .foregroundStyle(color)
            .help(status) // Tooltip for accessibility
    }

    var body: some View {
        if let commit = commit {
            HSplitView {
                // Left Side: Commit Info & File List
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Commit Metadata Group
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Commit Details")
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            HStack {
                                Image(systemName: "number")
                                Text(commit.hash)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }

                            HStack {
                                Image(systemName: "person.fill")
                                Text(commit.author)
                            }

                            HStack {
                                Image(systemName: "calendar")
                                Text(commit.date.formatted(date: .long, time: .shortened))
                            }
                        }
                        .padding(.bottom, 8)

                        Divider()

                        // Commit Message Group
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Message")
                                .font(.headline)
                            Text(commit.message)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 8)

                        Divider()

                        // Changed Files Group (Now Selectable)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Changed Files (\(commit.changedFiles.count))")
                                .font(.headline)

                            if commit.changedFiles.isEmpty {
                                Text("No files changed in this commit.")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 5)
                            } else {
                                // Make file rows selectable
                                ForEach(commit.changedFiles) { file in
                                    HStack {
                                        fileStatusIconView(file.status)
                                        Text(file.name)
                                        Spacer()
                                    }
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 5)
                                    .background(selectedFile == file ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .cornerRadius(4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedFile = file
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .padding()
                }
                .frame(minWidth: 300)

                // Right Side: Diff View
                DiffView(diffText: diffContent, isLoading: isLoadingDiff)
                    .frame(minWidth: 400)
            }
        } else {
            // Placeholder view when no commit is selected
            VStack {
                Spacer()
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 50))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 10)
                Text("Select a commit")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Details about the selected commit and changed files will appear here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// --- Preview ---
#Preview {
    GitClientView()
}
