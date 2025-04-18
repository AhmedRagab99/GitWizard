import SwiftUI

// Import all models
import Foundation

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

// Sidebar Item Types
enum SidebarItem: Hashable {
    case workspace(WorkspaceItem)
    case branch(Branch)
    case tag(Tag)
    case remote(String)

    enum WorkspaceItem: String, CaseIterable {
        case workingCopy = "Working Copy"
        case history = "History"
        case stashes = "Stashes"
        case pullRequests = "Pull Requests"
        case branchesReview = "Branches Review"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .workingCopy: return "folder.fill"
            case .history: return "clock.fill"
            case .stashes: return "doc.fill"
            case .pullRequests: return "arrow.triangle.branch"
            case .branchesReview: return "arrow.triangle.branch"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .workingCopy, .history, .stashes,
                 .pullRequests, .branchesReview, .settings:
                return .blue
            }
        }
    }
}

struct SidebarBranchView: View {
    let branch: Branch
    let isExpanded: Bool
    let hasSubbranches: Bool

    var body: some View {
        HStack(spacing: 6) {
            if hasSubbranches {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.blue)

            Text(branch.name)
                .lineLimit(1)

            if branch.isCurrent {
                Spacer()
                Text("HEAD")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}

struct SidebarTagView: View {
    let tag: Tag

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundColor(.blue)
            Text(tag.name)
                .lineLimit(1)
        }
    }
}

struct FilterBarView: View {
    @Binding var filterText: String
    var onAddClick: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter", text: $filterText)
                    .textFieldStyle(.plain)
            }
            .padding(6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            Button(action: onAddClick) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var filterText: String = ""
    @State private var expandedBranches: Set<String> = ["feature"]

    private func toggleBranch(_ branch: String) {
        if expandedBranches.contains(branch) {
            expandedBranches.remove(branch)
        } else {
            expandedBranches.insert(branch)
        }
    }

    private func groupBranches(_ branches: [Branch]) -> [String: [Branch]] {
        var groups: [String: [Branch]] = [:]

        for branch in branches {
            let components = branch.name.components(separatedBy: "/")
            if components.count > 1 {
                let groupName = components[0]
                groups[groupName, default: []].append(branch)
            } else {
                groups["", default: []].append(branch)
            }
        }

        return groups
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar with cloud sync status
            HStack {
                Text("Workspace")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.secondary)
                }
                Button(action: {}) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(selection: $viewModel.selectedSidebarItem) {
                // Workspace section
                Section {
                    ForEach(SidebarItem.WorkspaceItem.allCases, id: \.self) { item in
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                            Text(item.rawValue)
                        }
                        .tag(SidebarItem.workspace(item))
                    }
                }

                // Branches section
                Section("Branches") {
                    let branchGroups = groupBranches(viewModel.branches)

                    // Main branches
                    if let mainBranches = branchGroups[""] {
                        ForEach(mainBranches) { branch in
                            SidebarBranchView(
                                branch: branch,
                                isExpanded: false,
                                hasSubbranches: false
                            )
                            .tag(SidebarItem.branch(branch))
                        }
                    }

                    // Grouped branches
                    ForEach(Array(branchGroups.keys.sorted().filter { $0 != "" }), id: \.self) { group in
                        if let groupBranches = branchGroups[group] {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedBranches.contains(group) },
                                    set: { _ in toggleBranch(group) }
                                )
                            ) {
                                ForEach(groupBranches) { branch in
                                    SidebarBranchView(
                                        branch: branch,
                                        isExpanded: false,
                                        hasSubbranches: false
                                    )
                                    .tag(SidebarItem.branch(branch))
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(group)
                                }
                            }
                        }
                    }
                }

                // Tags section
                Section("Tags") {
                    ForEach(viewModel.tags) { tag in
                        SidebarTagView(tag: tag)
                            .tag(SidebarItem.tag(tag))
                    }
                }

                // Remotes section
                if !viewModel.repoInfo.remotes.isEmpty {
                    Section("Remotes") {
                        ForEach(viewModel.repoInfo.remotes, id: \.name) { remote in
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                Text(remote.name)
                            }
                            .tag(SidebarItem.remote(remote.name))
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            // Filter bar at bottom
            FilterBarView(filterText: $filterText) {
                // Add button action
            }
            .background(Color(.windowBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
    }
}

// Month Header View
struct MonthHeaderView: View {
    let date: Date

    var body: some View {
        Text(date.formatted(.dateTime.month(.wide).year()))
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor).opacity(0.8))
    }
}

// Branch Tag View
struct BranchTagView: View {
    let name: String
    let type: BranchType

    enum BranchType {
        case head
        case branch
        case tag
        case production

        var backgroundColor: Color {
            switch self {
            case .head: return .blue.opacity(0.2)
            case .branch: return .secondary.opacity(0.15)
            case .tag: return .green.opacity(0.2)
            case .production: return .purple.opacity(0.2)
            }
        }

        var textColor: Color {
            switch self {
            case .head: return .blue
            case .branch: return .secondary
            case .tag: return .green
            case .production: return .purple
            }
        }
    }

    var body: some View {
        Text(name)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.backgroundColor)
            .foregroundColor(type.textColor)
            .clipShape(Capsule())
    }
}

// Updated CommitGraphVisualization
struct CommitGraphVisualization: View {
    let commit: Commit
    let previousCommit: Commit?
    let nextCommit: Commit?
    @State private var isHovered = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let nodeSize: CGFloat = 14
            let lineWidth: CGFloat = 2

            Canvas { context, size in
                // Draw branch lines
                for (index, parentHash) in commit.parentHashes.enumerated() {
                    let startX = width / 2
                    let startY = height / 2
                    let endY = height

                    let path = Path { p in
                        p.move(to: CGPoint(x: startX, y: startY))
                        if commit.commitType == .merge && index > 0 {
                            // Draw merge line with curve
                            let controlX = startX - 20.0
                            p.addCurve(
                                to: CGPoint(x: startX, y: endY),
                                control1: CGPoint(x: controlX, y: startY),
                                control2: CGPoint(x: controlX, y: endY)
                            )
                        } else {
                            // Draw straight line for main branch
                            p.addLine(to: CGPoint(x: startX, y: endY))
                        }
                    }

                    context.stroke(
                        path,
                        with: .linearGradient(
                            .init(colors: [
                                commit.commitType == .merge ? .purple.opacity(0.3) : .blue.opacity(0.3),
                                commit.commitType == .merge ? .purple.opacity(0.1) : .blue.opacity(0.1)
                            ]),
                            startPoint: .init(x: 0, y: 0),
                            endPoint: .init(x: 0, y: size.height)
                        ),
                        lineWidth: lineWidth
                    )
                }
            }

            // Commit node
            Circle()
                .fill(commitColor)
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: commitColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                .position(x: width / 2, y: height / 2)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var commitColor: Color {
        switch commit.commitType {
        case .normal: return .blue
        case .merge: return .purple
        case .rebase: return .orange
        case .cherryPick: return .green
        case .revert: return .red
        default : return .blue
        }
    }
}

// Updated CommitRowView
struct CommitRowView: View {
    let commit: Commit
    let previousCommit: Commit?
    let nextCommit: Commit?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Graph visualization
            CommitGraphVisualization(
                commit: commit,
                previousCommit: previousCommit,
                nextCommit: nextCommit
            )
            .frame(width: 50)

            // Author image
            AsyncImage(url: URL(string: commit.authorAvatar)) { image in
                image
                    .resizable()
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: 24, height: 24)

            // Commit info
            VStack(alignment: .leading, spacing: 4) {
                // First line: commit message and tags
                HStack(spacing: 8) {
                    Text(commit.message)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)

                    // Tags and branch indicators
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            if commit.branchNames.contains("HEAD") {
                                BranchTagView(name: "HEAD", type: .head)
                            }
                            if commit.branchNames.contains("production") {
                                BranchTagView(name: "production", type: .production)
                            }
                            ForEach(commit.branchNames.filter { $0 != "HEAD" && $0 != "production" }, id: \.self) { branch in
                                BranchTagView(name: branch, type: .branch)
                            }
                        }
                    }
                }

                // Second line: metadata
                HStack(spacing: 16) {
                    Text(commit.hash.prefix(8))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(commit.author)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(commit.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isHovered ? Color(.windowBackgroundColor).opacity(0.5) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Updated HistoryView
struct HistoryView: View {
    @ObservedObject var viewModel: GitViewModel

    private func groupCommitsByMonth(_ commits: [Commit]) -> [(month: Date, commits: [Commit])] {
        let grouped = Dictionary(grouping: commits) { commit in
            Calendar.current.startOfMonth(for: commit.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (month: $0.key, commits: $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupCommitsByMonth(viewModel.branchCommits), id: \.month) { group in
                    Section(header: MonthHeaderView(date: group.month)) {
                        ForEach(Array(zip(group.commits.indices, group.commits)), id: \.0) { index, commit in
                            CommitRowView(
                                commit: commit,
                                previousCommit: index > 0 ? group.commits[index - 1] : nil,
                                nextCommit: index < group.commits.count - 1 ? group.commits[index + 1] : nil
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedCommit = commit
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.windowBackgroundColor))
    }
}

// Helper extension
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// --- Commit Detail View ---
struct CommitDetailHeader: View {
    let commit: Commit
    let refs: [String]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: ModernUI.spacing) {
            // Top bar with hash and actions
            HStack(spacing: ModernUI.spacing) {
                HStack(spacing: 4) {
                    Text(commit.hash.prefix(7))
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(ModernUI.colors.secondaryText)

                    Button {
                        // Copy hash action
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(ModernButtonStyle(style: .ghost))
                }

                Spacer()

                HStack(spacing: ModernUI.spacing) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(ModernButtonStyle(style: .ghost))

                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(ModernButtonStyle(style: .ghost))

                    Menu {
                        Button("Changeset", action: {})
                        Button("Tree", action: {})
                    } label: {
                        HStack {
                            Text("Changeset")
                            Image(systemName: "chevron.down")
                        }
                    }
                    .buttonStyle(ModernButtonStyle(style: .secondary))
                }
            }

            Divider()
                .background(ModernUI.colors.border)

            // Author info with animation
            VStack(alignment: .leading, spacing: ModernUI.spacing) {
                HStack(spacing: ModernUI.spacing) {
                    AsyncImage(url: URL(string: commit.authorAvatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(ModernUI.colors.secondaryText)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .modernShadow(.small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(commit.author)
                            .font(.headline)
                        Text(commit.authorEmail)
                            .font(.subheadline)
                            .foregroundColor(ModernUI.colors.secondaryText)
                    }
                }

                // Date with icon
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(ModernUI.colors.secondaryText)
                    Text(commit.date.formatted(.dateTime
                        .day().month(.wide).year()
                        .hour().minute()
                        .timeZone()))
                        .foregroundColor(ModernUI.colors.secondaryText)
                }

                // Refs with modern badges
                if !refs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(refs, id: \.self) { ref in
                                RefBadge(name: ref)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(ModernUI.padding)
            .background(ModernUI.colors.secondaryBackground)
            .cornerRadius(ModernUI.cornerRadius)
        }
        .padding(ModernUI.padding)
        .background(ModernUI.colors.background)
    }
}

// Modern Ref Badge
struct RefBadge: View {
    let name: String

    private var style: (background: Color, foreground: Color, icon: String) {
        if name == "HEAD" {
            return (.blue.opacity(0.2), .blue, "point.3.connected.trianglepath.dotted")
        } else if name == "production" {
            return (.purple.opacity(0.2), .purple, "checkmark.seal.fill")
        } else if name.hasPrefix("origin/") {
            return (.green.opacity(0.2), .green, "arrow.triangle.branch")
        } else {
            return (.secondary.opacity(0.2), .secondary, "tag.fill")
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.caption)
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.background)
        .foregroundColor(style.foreground)
        .cornerRadius(12)
    }
}

// Syntax Highlighting Colors
enum SyntaxTheme {
    static let added = Color.green.opacity(0.1)
    static let removed = Color.red.opacity(0.1)
    static let lineNumber = Color.gray.opacity(0.5)
    static let addedText = Color.green
    static let removedText = Color.red
    static let normalText = Color(.labelColor)
}

// Code Line View
struct CodeLineView: View {
    let line: String
    let lineNumber: Int
    let type: LineType

    enum LineType {
        case added, removed, normal

        var background: Color {
            switch self {
            case .added: return SyntaxTheme.added
            case .removed: return SyntaxTheme.removed
            case .normal: return .clear
            }
        }

        var textColor: Color {
            switch self {
            case .added: return SyntaxTheme.addedText
            case .removed: return SyntaxTheme.removedText
            case .normal: return SyntaxTheme.normalText
            }
        }

        var indicator: String {
            switch self {
            case .added: return "+"
            case .removed: return "-"
            case .normal: return " "
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text("\(lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(SyntaxTheme.lineNumber)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            // Change indicator
            Text(type.indicator)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(type.textColor)
                .frame(width: 20)

            // Code content
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(type.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(type.background)
    }
}

// File Type Styling
enum FileType {
    case swift
    case markdown
    case json
    case yaml
    case gitignore
    case other(String)

    init(from filename: String) {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": self = .swift
        case "md": self = .markdown
        case "json": self = .json
        case "yml", "yaml": self = .yaml
        case "":
            if filename.lowercased() == ".gitignore" {
                self = .gitignore
            } else {
                self = .other("")
            }
        default: self = .other(ext)
        }
    }

    var icon: String {
        switch self {
        case .swift: return "swift"
        case .markdown: return "doc.text"
        case .json: return "curlybraces"
        case .yaml: return "list.bullet.indent"
        case .gitignore: return "eye.slash"
        case .other: return "doc"
        }
    }

    var color: Color {
        switch self {
        case .swift: return .orange
        case .markdown: return .blue
        case .json: return .yellow
        case .yaml: return .green
        case .gitignore: return .gray
        case .other: return .secondary
        }
    }

    var label: String {
        switch self {
        case .swift: return "Swift"
        case .markdown: return "Markdown"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .gitignore: return "GitIgnore"
        case .other(let ext): return ext.uppercased()
        }
    }
}

// File Name View
struct FileNameView: View {
    let filename: String
    let fileType: FileType

    init(filename: String) {
        self.filename = filename
        self.fileType = FileType(from: filename)
    }

    private var directory: String? {
        let components = filename.components(separatedBy: "/")
        return components.count > 1 ? components.dropLast().joined(separator: "/") : nil
    }

    private var name: String {
        filename.components(separatedBy: "/").last ?? filename
    }

    var body: some View {
        HStack(spacing: 4) {
            // File icon
            Image(systemName: fileType.icon)
                .foregroundColor(fileType.color)
                .font(.system(size: 16))

            // Directory path (if exists)
            if let directory = directory {
                Text(directory + "/")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            }

            // File name
            Text(name)
                .foregroundColor(ModernUI.colors.text)
                .font(.system(size: 14, weight: .medium))

            // File type badge
            Text(fileType.label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(fileType.color.opacity(0.1))
                .foregroundColor(fileType.color)
                .cornerRadius(4)
        }
    }
}

// Update FileChangeSection to use FileNameView
struct FileChangeSection: View {
    let fileChange: FileChange
    let diffContent: String?
    @Binding var expandedFile: FileChange?
    @State private var isLoading = false

    private var isExpanded: Bool {
        expandedFile?.id == fileChange.id
    }

    private var statusColor: Color {
        switch fileChange.status {
        case "Added": return .green
        case "Modified": return .yellow
        case "Deleted": return .red
        case "Renamed": return .blue
        default: return .gray
        }
    }

    private func parseLines(_ content: String) -> [(line: String, type: CodeLineView.LineType)] {
        return content.components(separatedBy: .newlines).map { line in
            if line.hasPrefix("+") {
                return (String(line.dropFirst()), .added)
            } else if line.hasPrefix("-") {
                return (String(line.dropFirst()), .removed)
            } else {
                return (line, .normal)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: {
                withAnimation(ModernUI.animation) {
                    if isExpanded {
                        expandedFile = nil
                    } else {
                        expandedFile = fileChange
                        isLoading = true
                        // Simulate loading delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
                }
            }) {
                HStack(spacing: ModernUI.spacing) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(ModernUI.colors.secondaryText)
                        .frame(width: 20)

                    Image(systemName: fileChange.status == "Added" ? "plus.circle.fill" :
                            fileChange.status == "Modified" ? "pencil.circle.fill" :
                            fileChange.status == "Deleted" ? "minus.circle.fill" :
                            "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(statusColor)

                    FileNameView(filename: fileChange.name)

                    Spacer()

                    Text(fileChange.status)
                        .font(.caption)
                        .foregroundColor(ModernUI.colors.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, ModernUI.padding)
                .background(isExpanded ? ModernUI.colors.selection : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding()
                        Spacer()
                    }
                    .background(ModernUI.colors.secondaryBackground)
                } else if let diffContent = diffContent {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(parseLines(diffContent).enumerated()), id: \.offset) { index, line in
                                CodeLineView(
                                    line: line.line,
                                    lineNumber: index + 1,
                                    type: line.type
                                )
                            }
                        }
                        .padding(.vertical, ModernUI.padding)
                    }
                    .background(ModernUI.colors.secondaryBackground)
                    .transition(.opacity)
                }
            }
        }
        .background(ModernUI.colors.background)
        .cornerRadius(ModernUI.cornerRadius)
        .modernShadow(.small)
    }
}

// Updated CommitDetailView
struct CommitDetailView: View {
    let commit: Commit
    let details: GitViewModel.CommitDetails?
    @State private var expandedFile: FileChange?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: ModernUI.spacing) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading commit details...")
                        .foregroundColor(ModernUI.colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ModernUI.colors.background)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernUI.spacing, pinnedViews: [.sectionHeaders]) {
                        CommitDetailHeader(
                            commit: commit,
                            refs: details?.branchNames ?? []
                        )

                        // Commit message
                        Text(commit.message)
                            .font(.system(.body))
                            .padding(ModernUI.padding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ModernUI.colors.background)
                            .cornerRadius(ModernUI.cornerRadius)
                            .modernShadow(.small)

                        if let details = details {
                            // Changed files section
                            Section {
                                ForEach(details.changedFiles) { file in
                                    FileChangeSection(
                                        fileChange: file,
                                        diffContent: details.diffContent,
                                        expandedFile: $expandedFile
                                    )
                                }
                            } header: {
                                HStack {
                                    Text("Changed Files")
                                        .font(.headline)
                                    Text("(\(details.changedFiles.count))")
                                        .foregroundColor(ModernUI.colors.secondaryText)
                                    Spacer()
                                }
                                .padding(ModernUI.padding)
                                .background(ModernUI.colors.background)
                            }
                        }
                    }
                    .padding(ModernUI.padding)
                }
            }
        }
        .background(ModernUI.colors.background)
        .onAppear {
            withAnimation(ModernUI.animation.delay(0.3)) {
                isLoading = false
            }
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

// Modern UI Constants
enum ModernUI {
    static let cornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 12
    static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    static let colors = (
        background: Color(.windowBackgroundColor),
        secondaryBackground: Color(.controlBackgroundColor),
        accent: Color.blue,
        text: Color(.labelColor),
        secondaryText: Color(.secondaryLabelColor),
        border: Color(.separatorColor),
        selection: Color.blue.opacity(0.15)
    )

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func modernShadow(_ style: ModernUI.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    let style: Style
    @Environment(\.isEnabled) private var isEnabled

    enum Style {
        case primary, secondary, ghost

        var background: Color {
            switch self {
            case .primary: return ModernUI.colors.accent
            case .secondary: return ModernUI.colors.secondaryBackground
            case .ghost: return .clear
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .secondary, .ghost: return ModernUI.colors.text
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(style.background.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(style.foreground)
            .cornerRadius(ModernUI.cornerRadius)
            .opacity(isEnabled ? 1 : 0.5)
            .modernShadow(configuration.isPressed ? .small : .medium)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

