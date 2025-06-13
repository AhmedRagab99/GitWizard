import SwiftUI
import Foundation
import os.log

struct CommitView: View {
    @Bindable var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFileItem: FileDiff?
    @State private var isCommitting: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var fileToReset: String?
    @State private var hasConflicts: Bool = false
    @State private var conflictedFiles: [String] = []

    // Track visible files to optimize memory management
    @State private var visibleStagedFiles = Set<String>()
    @State private var visibleUnstagedFiles = Set<String>()
    @State private var visibleConflictedFiles = Set<String>()

    // Lazily load diff content
    @State private var shouldLoadDiff = false

    // State for DisclosureGroup
    @State private var isStagedExpanded: Bool = true
    @State private var isModifiedExpanded: Bool = true
    @State private var isUntrackedExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.conflictedFileDiffs.isEmpty {
                ConflictBanner(
                    conflictedFilesCount: viewModel.conflictedFileDiffs.count,
                    onAbortMerge: {
                        Task {
                            await viewModel.abortMerge()
                        }
                    }
                )
                .padding()
            }

            mainContent
        }
        .onAppear {
            Task {
                await viewModel.loadChanges()
                // Delay loading diff content until after initial UI rendering
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldLoadDiff = true
                }
            }
        }
        .onDisappear {
            // Clear references to free memory when view disappears
            selectedFileItem = nil
            viewModel.selectedFileDiff = nil
            shouldLoadDiff = false
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
        // Keep view model's selectedFileDiff and view's selectedFileItem in sync bidirectionally
        .onChange(of: selectedFileItem) { oldValue, newValue in
            viewModel.selectedFileDiff = newValue
        }
        .onChange(of: viewModel.selectedFileDiff) { oldValue, newValue in
            if newValue?.id != selectedFileItem?.id {
                selectedFileItem = newValue
            }
        }
        // Update when stagedDiff or unstagedDiff changes
        .onChange(of: viewModel.stagedDiff) { oldValue, newValue in
            updateSelectedFile()
        }
        .onChange(of: viewModel.unstagedDiff) { oldValue, newValue in
            updateSelectedFile()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Left pane - Staged, Modified, and Untracked changes
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Conflicts Section
                        if !viewModel.conflictedFileDiffs.isEmpty {
                            ChangesSection(
                                title: "Conflicts",
                                icon: "exclamationmark.triangle.fill",
                                iconColor: .red,
                                files: viewModel.conflictedFileDiffs,
                                selectedFile: $selectedFileItem,
                                visibleFiles: $visibleConflictedFiles,
                                isExpanded: .constant(true), // Always expanded
                                actionIcon: "", // No primary action
                                actionColor: .clear,
                                action: { _ in },
                                onResolveWithMine: { file in
                                    let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    Task { await viewModel.resolveConflictUsingOurs(filePath: path) }
                                },
                                onResolveWithTheirs: { file in
                                    let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    Task { await viewModel.resolveConflictUsingTheirs(filePath: path) }
                                },
                                onMarkAsResolved: { file in
                                    let path = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                    Task { await viewModel.markConflictResolved(filePath: path) }
                                }
                            )
                        }

                        // Staged changes section
                        ChangesSection(
                            title: "Staged Changes",
                            icon: "tray.full.fill",
                            iconColor: .green,
                            files: viewModel.stagedDiff?.fileDiffs ?? [],
                            selectedFile: $selectedFileItem,
                            visibleFiles: $visibleStagedFiles,
                            isExpanded: $isStagedExpanded,
                            actionIcon: "minus.circle.fill",
                            actionColor: .orange,
                            action: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } },
                            onUnstage: { file in Task { await viewModel.unstageFile(path: file.fromFilePath) } },
                            onReset: { file in
                                fileToReset = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                showResetConfirm = true
                            },
                            onHeaderAction: { Task { await viewModel.unstageAllChanges() } },
                            headerActionTitle: "Unstage All",
                            isStaged: true
                        )

                        // Modified (Unstaged) changes section
                        ChangesSection(
                            title: "Modified Files",
                            icon: "pencil.circle.fill",
                            iconColor: .orange,
                            files: viewModel.unstagedDiff?.fileDiffs ?? [],
                            selectedFile: $selectedFileItem,
                            visibleFiles: $visibleUnstagedFiles,
                            isExpanded: $isModifiedExpanded,
                            actionIcon: "plus.circle.fill",
                            actionColor: .green,
                            action: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } },
                            onStage: { file in Task { await viewModel.stageFile(path: file.fromFilePath) } },
                            onReset: { file in
                                fileToReset = file.fromFilePath.isEmpty ? file.toFilePath : file.fromFilePath
                                showResetConfirm = true
                            },
                            onHeaderAction: { Task { await viewModel.stageAllChanges() } },
                            headerActionTitle: "Stage All",
                            isStaged: false
                        )

                        // Untracked files section
                        if !viewModel.untrackedFiles.isEmpty {
                            UntrackedFilesSection(
                                files: viewModel.untrackedFiles,
                                isExpanded: $isUntrackedExpanded,
                                onStage: { path in Task { await viewModel.stageFile(path: path) } },
                                onIgnore: { path in Task { await viewModel.addToGitignore(path: path) } },
                                onTrash: { path in Task { await viewModel.moveToTrash(path: path) } }
                            )
                        }
                    }
                    .padding()
                }
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .frame(minWidth: 340, maxWidth: 420)

                // Right pane - Diff view (lazy loaded)
                if shouldLoadDiff {
                    rightPane
                } else {
                    loadingPlaceholder
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
    }

    @ViewBuilder
    private var loadingPlaceholder: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading diff view...")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(16)
    }

    @ViewBuilder
    private var rightPane: some View {
        if let selectedFile = selectedFileItem {
            FileDiffContainerView(viewModel: viewModel, fileDiff: selectedFile)
                .frame(minWidth: 400)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(16)
                .shadow(color: Color.accentColor.opacity(0.08), radius: 6, x: 0, y: 2)
                .padding(.vertical, 8)
                .toolbar {
                    if selectedFile.status == .conflict {
                        ToolbarItemGroup(placement: .primaryAction) {
                            Menu {
                                Button("Keep Our Changes") {
                                    let path = selectedFile.fromFilePath.isEmpty ? selectedFile.toFilePath : selectedFile.fromFilePath
                                    Task { await viewModel.resolveConflictUsingOurs(filePath: path) }
                                }
                                Button("Keep Their Changes") {
                                    let path = selectedFile.fromFilePath.isEmpty ? selectedFile.toFilePath : selectedFile.fromFilePath
                                    Task { await viewModel.resolveConflictUsingTheirs(filePath: path) }
                                }
                                Divider()
                                Button("Mark as Resolved") {
                                    let path = selectedFile.fromFilePath.isEmpty ? selectedFile.toFilePath : selectedFile.fromFilePath
                                    Task { await viewModel.markConflictResolved(filePath: path) }
                                }
                            } label: {
                                Label("Resolve Conflict", systemImage: "exclamationmark.triangle")
                            }
                        }
                    }
                }
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

    private func checkForConflicts() async {
        hasConflicts = await viewModel.hasConflicts()
        if hasConflicts {
            conflictedFiles = await viewModel.getConflictedFiles()
        }
    }

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
            if hasConflicts {
                Label("\(conflictedFiles.count) conflicts", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            Spacer()
            if let staged = viewModel.stagedDiff?.fileDiffs.count, staged > 0 {
                Text("Ready to commit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func updateSelectedFile() {
        if let selectedFileId = selectedFileItem?.id {
            let allFiles = (viewModel.stagedDiff?.fileDiffs ?? []) + (viewModel.unstagedDiff?.fileDiffs ?? [])
            if !allFiles.contains(where: { $0.id == selectedFileId }) {
                selectedFileItem = nil
            }
        }
    }
}

// MARK: - Reusable Changes Section
struct ChangesSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    @Binding var visibleFiles: Set<String>
    @Binding var isExpanded: Bool
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void
    var onStage: ((FileDiff) -> Void)? = nil
    var onUnstage: ((FileDiff) -> Void)? = nil
    var onReset: ((FileDiff) -> Void)? = nil
    var onHeaderAction: (() -> Void)? = nil
    var headerActionTitle: String? = nil
    var isStaged: Bool = false
    var onResolveWithMine: ((FileDiff) -> Void)? = nil
    var onResolveWithTheirs: ((FileDiff) -> Void)? = nil
    var onMarkAsResolved: ((FileDiff) -> Void)? = nil

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if !files.isEmpty {
                OptimizedFileListView(
                    files: files,
                    selectedFile: $selectedFile,
                    visibleFiles: $visibleFiles,
                    actionIcon: actionIcon,
                    actionColor: actionColor,
                    action: action,
                    onStage: onStage,
                    onUnstage: onUnstage,
                    onReset: onReset,
                    onResolveWithMine: onResolveWithMine,
                    onResolveWithTheirs: onResolveWithTheirs,
                    onMarkAsResolved: onMarkAsResolved,
                    isStaged: isStaged
                )
            } else {
                EmptyStateView(message: "No \(title.lowercased())")
                    .padding()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .fontWeight(.semibold)
                Text("(\(files.count))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                if let onHeaderAction = onHeaderAction, let headerActionTitle = headerActionTitle, !files.isEmpty {
                    Button(headerActionTitle) {
                        onHeaderAction()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Reusable Untracked Files Section
struct UntrackedFilesSection: View {
    let files: [String]
    @Binding var isExpanded: Bool
    let onStage: (String) -> Void
    let onIgnore: (String) -> Void
    let onTrash: (String) -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(files, id: \.self) { path in
                        UntrackedFileRow(
                            path: path,
                            action: { onStage(path) },
                            onIgnore: { onIgnore(path) },
                            onTrash: { onTrash(path) }
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
        } label: {
            HStack {
                Image(systemName: FileStatus.untracked.icon)
                    .foregroundColor(FileStatus.untracked.color)
                Text("Untracked Files")
                    .fontWeight(.semibold)
                Text("(\(files.count))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Memory-optimized File List View
struct OptimizedFileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    @Binding var visibleFiles: Set<String>
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void
    var onStage: ((FileDiff) -> Void)? = nil
    var onUnstage: ((FileDiff) -> Void)? = nil
    var onReset: ((FileDiff) -> Void)? = nil
    var onIgnore: ((FileDiff) -> Void)? = nil
    var onTrash: ((FileDiff) -> Void)? = nil
    var onResolveWithMine: ((FileDiff) -> Void)? = nil
    var onResolveWithTheirs: ((FileDiff) -> Void)? = nil
    var onMarkAsResolved: ((FileDiff) -> Void)? = nil
    var isStaged: Bool = false

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
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedFiles, id: \.status) { group in
                    ForEach(group.files, id: \.fromFilePath) { file in
                        ModernFileRow(
                            fileDiff: file,
                            isSelected: selectedFile?.id == file.id,
                            actionIcon: actionIcon,
                            actionColor: actionColor,
                            action: { action(file) },
                            onStage: onStage != nil ? { onStage?(file) } : nil,
                            onUnstage: onUnstage != nil ? { onUnstage?(file) } : nil,
                            onReset: onReset != nil ? { onReset?(file) } : nil,
                            onIgnore: onIgnore != nil ? { onIgnore?(file) } : nil,
                            onTrash: onTrash != nil ? { onTrash?(file) } : nil,
                            onResolveWithMine: onResolveWithMine != nil ? { onResolveWithMine?(file) } : nil,
                            onResolveWithTheirs: onResolveWithTheirs != nil ? { onResolveWithTheirs?(file) } : nil,
                            onMarkAsResolved: onMarkAsResolved != nil ? { onMarkAsResolved?(file) } : nil,
                            isStaged: isStaged
                        )
                        .onTapGesture { selectedFile = file }
                        .onAppear { visibleFiles.insert(file.id) }
                        .onDisappear { visibleFiles.remove(file.id) }
                    }
                }
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let message: String
    var body: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}
