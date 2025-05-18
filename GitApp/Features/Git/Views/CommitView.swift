import SwiftUI
import Foundation

struct CommitView: View {
    @Bindable var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFileItem: FileDiff?
    @State private var isCommitting: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var fileToReset: String?

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
                                action: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } },
                                onUnstage: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } },
                                onReset: { file in
                                    fileToReset = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    showResetConfirm = true
                                },
                                onIgnore: { file in
                                    let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    Task { await viewModel.addToGitignore(path: path) }
                                },
                                onTrash: { file in
                                    let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    Task { await viewModel.moveToTrash(path: path) }
                                },
                                isStaged: true
                            )
                        } else {
                            EmptyStateView(message: "No staged changes")
                        }
                    }
                    SectionCard(
                        title: "Unstaged Changes",
                        count: (viewModel.unstagedDiff?.fileDiffs.count ?? 0) + viewModel.untrackedFiles.count,
                        actionTitle: "Stage All",
                        action: { Task { await viewModel.stageAllChanges() } },
                        showAction: ((viewModel.unstagedDiff?.fileDiffs.isEmpty == false) || !viewModel.untrackedFiles.isEmpty),
                        icon: "tray.fill",
                        iconColor: .orange
                    ) {
                        if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty || !viewModel.untrackedFiles.isEmpty {
                            VStack(spacing: 8) {
                                ModernFileListView(
                                    files: unstagedDiff.fileDiffs,
                                    selectedFile: $selectedFileItem,
                                    actionIcon: "plus.circle.fill",
                                    actionColor: .green,
                                    action: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } },
                                    onStage: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } },
                                    onReset: { file in
                                        fileToReset = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                        showResetConfirm = true
                                    },
                                    onIgnore: { file in
                                        let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                        Task { await viewModel.addToGitignore(path: path) }
                                    },
                                    onTrash: { file in
                                        let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                        Task { await viewModel.moveToTrash(path: path) }
                                    }
                                )

                                // Untracked files
                                if !viewModel.untrackedFiles.isEmpty {
                                    SectionCard(title: FileStatus.untracked.rawValue, count: viewModel.untrackedFiles.count, actionTitle: "", action: {
                                        
                                    }, showAction: false, icon: FileStatus.untracked.icon, iconColor: FileStatus.untracked.color) {
                                        ForEach(viewModel.untrackedFiles, id: \.self) { path in
                                            UntrackedFileRow(
                                                path: path,
                                                action: { Task { await viewModel.stageFile(path: path) } },
                                                onIgnore: { Task { await viewModel.addToGitignore(path: path) } },
                                                onTrash: { Task { await viewModel.moveToTrash(path: path) } }
                                            )
                                        }
                                    }

                                }
                            }
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
        }
        .onAppear {
            Task { await viewModel.loadChanges() }
        }
        .loading(viewModel.isLoading)
        .errorAlert(viewModel.errorMessage)
        .confirmationDialog(
            "Are you sure you want to reset this file? This will discard all changes.",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset File", role: .destructive) {
                if let path = fileToReset {
                    Task {
                        await viewModel.resetFile(path: path)
                        fileToReset = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                fileToReset = nil
            }
        } message: {
            if let path = fileToReset {
                Text("This will discard all changes to \(path.components(separatedBy: "/").last ?? path)")
            }
        }
    }

    // Summary row similar to SourceTree
    private var summaryRow: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.stagedDiff?.fileDiffs.count ?? 0) staged", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Label("\(viewModel.unstagedDiff?.fileDiffs.count ?? 0) modified", systemImage: "pencil")
                .foregroundStyle(.blue)
            if !viewModel.untrackedFiles.isEmpty {
                Label("\(viewModel.untrackedFiles.count) untracked", systemImage: "plus")
                    .foregroundStyle(.orange)
            }
            Spacer()
            if let staged = viewModel.stagedDiff?.fileDiffs.count, staged > 0 {
                Text("Ready to commit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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
