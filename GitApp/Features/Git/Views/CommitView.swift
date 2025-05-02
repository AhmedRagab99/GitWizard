import SwiftUI
import Foundation

struct CommitView: View {
    @Bindable var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFileItem: FileDiff?

    var body: some View {
        HSplitView {
            // Left pane - Staged and Unstaged changes
            VStack(spacing: 0) {
                // Staged Changes Section
                sectionHeader(title: "Staged Changes", count: viewModel.stagedDiff?.fileDiffs.count ?? 0, actionTitle: "Unstage All", action: {
                    Task { await viewModel.unstageAllChanges() }
                }, showAction: (viewModel.stagedDiff?.fileDiffs.isEmpty == false))
                if let stagedDiff = viewModel.stagedDiff, !stagedDiff.fileDiffs.isEmpty {
                    FileListView(
                        files: stagedDiff.fileDiffs,
                        selectedFile: $selectedFileItem,
                        actionIcon: "minus.circle.fill",
                        actionColor: .orange,
                        action: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } }
                    )
                } else {
                    emptyState("No staged changes")
                }
                Divider().padding(.vertical, 4)
                // Unstaged Changes Section
                sectionHeader(title: "Unstaged Changes", count: viewModel.unstagedDiff?.fileDiffs.count ?? 0, actionTitle: "Stage All", action: {
                    Task { await viewModel.stageAllChanges() }
                }, showAction: (viewModel.unstagedDiff?.fileDiffs.isEmpty == false))
                if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty {
                    FileListView(
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
                Divider().padding(.vertical, 4)
                // Commit Message Area
                CommitMessageArea(
                    commitMessage: $commitMessage,
                    onCommit: {
                        Task {
                            await viewModel.commitChanges(message: commitMessage)
                            commitMessage = ""
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(minWidth: 320, maxWidth: 400)
            .background(Color(.windowBackgroundColor))

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
        .onAppear {
            Task { await viewModel.loadChanges() }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, count: Int, actionTitle: String, action: @escaping () -> Void, showAction: Bool) -> some View {
        HStack {
            Text("")
            Text(title)
                .font(.headline)
            Text("\(count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if showAction {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }

    @ViewBuilder
    private func emptyState(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

struct FileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void

    var body: some View {
        List(files, id: \.fromFilePath) { file in
            FileRow(
                fileDiff: file,
                isSelected: selectedFile?.fromFilePath == file.fromFilePath,
                actionIcon: actionIcon,
                actionColor: actionColor,
                action: { action(file) }
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowBackground(
                selectedFile?.fromFilePath == file.fromFilePath ?
                Color.accentColor.opacity(0.1) : Color.clear
            )
            .onTapGesture { selectedFile = file }
        }
        .listStyle(.plain)
        .frame(maxHeight: 180)
    }
}

struct FileRow: View {
    let fileDiff: FileDiff
    let isSelected: Bool
    let actionIcon: String
    let actionColor: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fileDiff.status.icon)
                .foregroundStyle(fileDiff.status.color)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20)
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
            Button(action: action) {
                Image(systemName: actionIcon)
                    .foregroundStyle(actionColor)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct CommitMessageArea: View {
    @Binding var commitMessage: String
    let onCommit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $commitMessage)
                .font(.system(size: 13))
                .frame(height: 100)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .padding()
            HStack {
                Spacer()
                Button(action: onCommit) {
                    Text("Commit")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing)
            }
            .padding(.bottom)
        }
        .background(Color(.controlBackgroundColor))
    }
}

#Preview {
    CommitView(viewModel: GitViewModel())
}
