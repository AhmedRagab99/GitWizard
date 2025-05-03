import SwiftUI
import Foundation

struct CommitView: View {
    @Bindable var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFileItem: FileDiff?

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Left pane - Staged and Unstaged changes
                VStack(spacing: 16) {
                    // Staged Changes Section
                    ModernSectionHeader(
                        title: "Staged Changes",
                        count: viewModel.stagedDiff?.fileDiffs.count ?? 0,
                        actionTitle: "Unstage All",
                        action: {
                            Task { await viewModel.unstageAllChanges() }
                        },
                        showAction: (viewModel.stagedDiff?.fileDiffs.isEmpty == false),
                        icon: "tray.full.fill",
                        iconColor: .green
                    )
                    if let stagedDiff = viewModel.stagedDiff, !stagedDiff.fileDiffs.isEmpty {
                        ModernFileListView(
                            files: stagedDiff.fileDiffs,
                            selectedFile: $selectedFileItem,
                            actionIcon: "minus.circle.fill",
                            actionColor: .orange,
                            action: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } }
                        )
                    } else {
                        emptyState("No staged changes")
                    }
                    // Unstaged Changes Section
                    ModernSectionHeader(
                        title: "Unstaged Changes",
                        count: viewModel.unstagedDiff?.fileDiffs.count ?? 0,
                        actionTitle: "Stage All",
                        action: {
                            Task { await viewModel.stageAllChanges() }
                        },
                        showAction: (viewModel.unstagedDiff?.fileDiffs.isEmpty == false),
                        icon: "tray.fill",
                        iconColor: .orange
                    )
                    if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty {
                        ModernFileListView(
                            files: unstagedDiff.fileDiffs,
                            selectedFile: $selectedFileItem,
                            actionIcon: "plus.circle.fill",
                            actionColor: .green,
                            action: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } }
                        )
                    } else {
                        emptyState("No unstaged changes")
                    }
                    Spacer(minLength: 0)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                .frame(minWidth: 340, maxWidth: 420)
                // Right pane - Diff view
                if let selectedFile = selectedFileItem {
                    FileDiffContainerView(viewModel: viewModel, fileDiff: selectedFile)
                        .frame(minWidth: 400)
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
                }
            }
            Divider()
            CommitMessageArea(
                commitMessage: $commitMessage,
                onCommit: {
                    Task {
                        await viewModel.commitChanges(message: commitMessage)
                        commitMessage = ""
                    }
                }
            )
            .padding(.vertical)
            .padding(.horizontal)
            
            summaryRow
                .padding(.horizontal)
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

    @ViewBuilder
    private func emptyState(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

// Modern Section Header
struct ModernSectionHeader: View {
    let title: String
    let count: Int
    let actionTitle: String
    let action: () -> Void
    let showAction: Bool
    let icon: String
    let iconColor: Color

    var body: some View {
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
    }
}

// Modern File List View
struct ModernFileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(files, id: \.fromFilePath) { file in
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
        .padding(.vertical, 2)
    }
}

// Modern File Row
struct ModernFileRow: View {
    let fileDiff: FileDiff
    let isSelected: Bool
    let actionIcon: String
    let actionColor: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(fileDiff.status.color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: fileDiff.status.icon)
                    .foregroundStyle(fileDiff.status.color)
                    .font(.system(size: 14, weight: .medium))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(fileDiff.fromFilePath.components(separatedBy: "/").last ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(fileDiff.fromFilePath)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            StatusBadge(status: fileDiff.status)
            Button(action: action) {
                Image(systemName: actionIcon)
                    .foregroundStyle(actionColor)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(NSColor.windowBackgroundColor).opacity(0.7))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.08) : .clear, radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color(.systemGreen).opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// Status Badge
struct StatusBadge: View {
    let status: FileStatus
    var body: some View {
        Text(status.shortDescription)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.18))
            .foregroundStyle(status.color)
            .cornerRadius(6)
    }
}

struct CommitMessageArea: View {
    @Binding var commitMessage: String
    let onCommit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "pencil")
//                    .foregroundStyle(.)
                Text("Commit Message")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 2)
            TextEditor(text: $commitMessage)
                .font(.system(size: 13))
                .frame(height: 80)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            HStack {
                Spacer()
                Button(action: onCommit) {
                    Label("Commit", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CommitView(viewModel: GitViewModel())
}
