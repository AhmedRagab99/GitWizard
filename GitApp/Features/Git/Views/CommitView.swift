import SwiftUI
import Foundation

struct CommitView: View {
    @Bindable var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFileItem: FileDiff?
    @State private var isCommitting: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Left pane - Staged and Unstaged changes
                VStack(spacing: 20) {
                    SectionCard(
                        title: "Staged Changes",
                        count: viewModel.stagedDiff?.fileDiffs.count ?? 0,
                        actionTitle: "Unstage All",
                        action: { Task { await viewModel.unstageAllChanges() } },
                        showAction: (viewModel.stagedDiff?.fileDiffs.isEmpty == false),
                        icon: "tray.full.fill",
                        iconColor: .green
                    ) {
                        if let stagedDiff = viewModel.stagedDiff, !stagedDiff.fileDiffs.isEmpty {
                            ModernFileListView(
                                files: stagedDiff.fileDiffs,
                                selectedFile: $selectedFileItem,
                                actionIcon: "minus.circle.fill",
                                actionColor: .orange,
                                action: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } }
                            )
                        } else {
                            EmptyStateView(message: "No staged changes")
                        }
                    }
                    SectionCard(
                        title: "Unstaged Changes",
                        count: viewModel.unstagedDiff?.fileDiffs.count ?? 0,
                        actionTitle: "Stage All",
                        action: { Task { await viewModel.stageAllChanges() } },
                        showAction: (viewModel.unstagedDiff?.fileDiffs.isEmpty == false),
                        icon: "tray.fill",
                        iconColor: .orange
                    ) {
                        if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty {
                            ModernFileListView(
                                files: unstagedDiff.fileDiffs,
                                selectedFile: $selectedFileItem,
                                actionIcon: "plus.circle.fill",
                                actionColor: .green,
                                action: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } }
                            )
                        } else {
                            EmptyStateView(message: "No unstaged changes")
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                .frame(minWidth: 340, maxWidth: 420)
                // Right pane - Diff view
                if let selectedFile = selectedFileItem {
                    FileDiffContainerView(viewModel: viewModel, fileDiff: selectedFile)
                        .frame(minWidth: 400)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(16)
                        .shadow(color: Color.accentColor.opacity(0.08), radius: 6, x: 0, y: 2)
                        .padding(.vertical, 8)
                } else {
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Select a file to view changes")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(16)
                }
            }
            Divider()
            CommitMessageArea(
                commitMessage: $commitMessage,
                isCommitting: $isCommitting,
                stagedCount: viewModel.stagedDiff?.fileDiffs.count ?? 0,
                onCommit: {
                    isCommitting = true
                    Task {
                        await viewModel.commitChanges(message: commitMessage)
                        commitMessage = ""
                        isCommitting = false
                    }
                }
            )
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            summaryRow
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            .onAppear {
                Task { await viewModel.loadChanges() }
            }
        }
    }

    // Summary row similar to SourceTree
    private var summaryRow: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.stagedDiff?.fileDiffs.count ?? 0) staged", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Label("\(viewModel.unstagedDiff?.fileDiffs.count ?? 0) unstaged", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Spacer()
            if let staged = viewModel.stagedDiff?.fileDiffs.count, staged > 0 {
                Text("Ready to commit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Section Card
struct SectionCard<Content: View>: View {
    let title: String
    let count: Int
    let actionTitle: String
    let action: () -> Void
    let showAction: Bool
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, count: Int, actionTitle: String, action: @escaping () -> Void, showAction: Bool, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.actionTitle = actionTitle
        self.action = action
        self.showAction = showAction
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.title3.bold())
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if showAction {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.systemGray))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.systemGray).opacity(0.2))
            )
            .padding(.bottom, 2)
            content
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Modern File List View
struct ModernFileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void

    private var groupedFiles: [(status: FileStatus, files: [FileDiff])] {
        Dictionary(grouping: files, by: { $0.status })
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        if files.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("No files to show")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor).opacity(0.7))
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedFiles, id: \ .status) { group in
                        Section(header: FileStatusHeader(status: group.status, count: group.files.count)) {
                            ForEach(group.files, id: \ .fromFilePath) { file in
                                ModernFileRow(
                                    fileDiff: file,
                                    isSelected: selectedFile?.fromFilePath == file.fromFilePath,
                                    actionIcon: actionIcon,
                                    actionColor: actionColor,
                                    action: { action(file) }
                                )
                                .onTapGesture { selectedFile = file }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct FileStatusHeader: View {
    let status: FileStatus
    let count: Int
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
            Text(status.rawValue)
                .font(.subheadline.bold())
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.controlBackgroundColor).opacity(0.95))
    }
}

// MARK: - Modern File Row
struct ModernFileRow: View {
    let fileDiff: FileDiff
    let isSelected: Bool
    let actionIcon: String
    let actionColor: Color
    let action: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(fileDiff.status.color.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: fileDiff.status.icon)
                    .foregroundStyle(fileDiff.status.color)
                    .font(.system(size: 15, weight: .medium))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(fileDiff.fromFilePath.components(separatedBy: "/").last ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(fileDiff.fromFilePath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            // Line stats
            if fileDiff.lineStats.added > 0 {
                Text("+\(fileDiff.lineStats.added)")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 4)
            }
            if fileDiff.lineStats.removed > 0 {
                Text("-\(fileDiff.lineStats.removed)")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
            StatusBadge(status: fileDiff.status)
            Button(action: action) {
                Image(systemName: actionIcon)
                    .foregroundStyle(actionColor)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.7)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : (isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7)))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.10) : .clear, radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color(.systemGray).opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { hovering in isHovered = hovering }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileDiff.fromFilePath), status: \(fileDiff.status.rawValue)")
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: FileStatus
    var body: some View {
        Text(status.shortDescription)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.18))
            .foregroundStyle(status.color)
            .cornerRadius(6)
    }
}

// MARK: - Commit Message Area
struct CommitMessageArea: View {
    @Binding var commitMessage: String
    @Binding var isCommitting: Bool
    let stagedCount: Int
    let onCommit: () -> Void
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedTemplate: String = ""

    let templates = [
        "feat: <description>\n\n[optional body]",
        "fix: <description>\n\n[optional body]",
        "chore: <description>\n\n[optional body]",
        "docs: <description>\n\n[optional body]"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.and.outline")
                Text("Commit Message")
                    .font(.headline)
                if stagedCount > 0 {
                    Text("\(stagedCount)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.18))
                        .cornerRadius(6)
                        .accessibilityLabel("\(stagedCount) files staged")
                }
                Spacer()
                Menu {
                    ForEach(templates, id: \.self) { template in
                        Button(template.prefix(20) + "...", action: {
                            commitMessage = template
                        })
                    }
                } label: {
                    Label("Templates", systemImage: "doc.text")
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $commitMessage)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(height: 90)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                if commitMessage.isEmpty {
                    Text("Enter a descriptive commit message...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 18)
                        .padding(.leading, 24)
                        .font(.system(size: 15, design: .monospaced))
                        .allowsHitTesting(false)
                }
            }
            .padding(.bottom, 8)
            HStack {
                if showError {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.leading, 16)
                }
                Spacer()
                Button(action: {
                    if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errorMessage = "Commit message cannot be empty."
                        showError = true
                        return
                    }
                    showError = false
                    onCommit()
                }) {
                    if isCommitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Label("Commit", systemImage: "arrow.up.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCommitting)
                .padding(.trailing, 16)
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
        .padding(.top, 6)
        .padding(.horizontal, 0)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let message: String
    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(12)
    }
}

// Utility for line stats
extension FileDiff {
    var lineStats: (added: Int, removed: Int) {
        let added = chunks.flatMap { $0.lines }.filter { $0.kind == .added }.count
        let removed = chunks.flatMap { $0.lines }.filter { $0.kind == .removed }.count
        return (added, removed)
    }
}

#Preview {
    CommitView(viewModel: GitViewModel())
}
