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

    // Lazily load diff content
    @State private var shouldLoadDiff = false

    // State for DisclosureGroup
    @State private var isStagedExpanded: Bool = true
    @State private var isModifiedExpanded: Bool = true
    @State private var isUntrackedExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            if hasConflicts {
                ConflictBanner(conflictedFiles: conflictedFiles)
            }

            mainContent
        }
        .onAppear {
            Task {
                await viewModel.loadChanges()
                await checkForConflicts()
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
                        // Staged changes section
                        DisclosureGroup(
                            isExpanded: $isStagedExpanded,
                            content: {
                                if let stagedDiff = viewModel.stagedDiff, !stagedDiff.fileDiffs.isEmpty {
                                    OptimizedFileListView(
                                        files: stagedDiff.fileDiffs,
                                        selectedFile: $selectedFileItem,
                                        visibleFiles: $visibleStagedFiles,
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
                                        .padding()
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: "tray.full.fill")
                                        .foregroundColor(.green)
                                    Text("Staged Changes")
                                        .fontWeight(.semibold)
                                    Text("(\(viewModel.stagedDiff?.fileDiffs.count ?? 0))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if viewModel.stagedDiff?.fileDiffs.isEmpty == false {
                                        Button("Unstage All") {
                                            Task { await viewModel.unstageAllChanges() }
                                        }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        )

                        // Modified (Unstaged) changes section
                        DisclosureGroup(
                            isExpanded: $isModifiedExpanded,
                            content: {
                                if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty {
                                    OptimizedFileListView(
                                        files: unstagedDiff.fileDiffs,
                                        selectedFile: $selectedFileItem,
                                        visibleFiles: $visibleUnstagedFiles,
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
                                } else {
                                    EmptyStateView(message: "No modified files")
                                        .padding()
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Modified Files")
                                        .fontWeight(.semibold)
                                    Text("(\(viewModel.unstagedDiff?.fileDiffs.count ?? 0))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if ((viewModel.unstagedDiff?.fileDiffs.isEmpty == false) || !viewModel.untrackedFiles.isEmpty) {
                                        Button("Stage All") {
                                            Task { await viewModel.stageAllChanges() }
                                        }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        )

                        // Untracked files section
                        if !viewModel.untrackedFiles.isEmpty {
                            DisclosureGroup(
                                isExpanded: $isUntrackedExpanded,
                                content: {
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
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
                                    .frame(maxHeight: 200)
                                },
                                label: {
                                    HStack {
                                        Image(systemName: FileStatus.untracked.icon)
                                            .foregroundColor(FileStatus.untracked.color)
                                        Text("Untracked Files")
                                            .fontWeight(.semibold)
                                        Text("(\(viewModel.untrackedFiles.count))")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
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

    private func showConflictMenu(for path: String) {
        let menu = NSMenu(title: "Resolve Conflicts")

        let ourChangesItem = NSMenuItem(title: "Keep Our Changes", action: #selector(NSApp.sendAction(_:to:from:)), keyEquivalent: "")
        ourChangesItem.target = nil
        ourChangesItem.action = #selector(NSApplication.shared.sendAction(_:to:from:))
        ourChangesItem.representedObject = {
            Task { await viewModel.resolveConflictUsingOurs(filePath: path) }
        }

        let theirChangesItem = NSMenuItem(title: "Keep Their Changes", action: #selector(NSApp.sendAction(_:to:from:)), keyEquivalent: "")
        theirChangesItem.target = nil
        theirChangesItem.action = #selector(NSApplication.shared.sendAction(_:to:from:))
        theirChangesItem.representedObject = {
            Task { await viewModel.resolveConflictUsingTheirs(filePath: path) }
        }

        let markResolvedItem = NSMenuItem(title: "Mark as Resolved", action: #selector(NSApp.sendAction(_:to:from:)), keyEquivalent: "")
        markResolvedItem.target = nil
        markResolvedItem.action = #selector(NSApplication.shared.sendAction(_:to:from:))
        markResolvedItem.representedObject = {
            Task { await viewModel.markConflictResolved(filePath: path) }
        }

        menu.addItem(ourChangesItem)
        menu.addItem(theirChangesItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(markResolvedItem)

        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
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

    // Helper to update selectedFileItem after git operations
    private func updateSelectedFile() {
        if let selectedFileId = selectedFileItem?.id {
            // Check if selected file is still available in staged or unstaged files
            let stagedFiles = viewModel.stagedDiff?.fileDiffs ?? []
            let unstagedFiles = viewModel.unstagedDiff?.fileDiffs ?? []

            // Try to find file by ID first
            if let stagedFile = stagedFiles.first(where: { $0.id == selectedFileId }) {
                selectedFileItem = stagedFile
            } else if let unstagedFile = unstagedFiles.first(where: { $0.id == selectedFileId }) {
                selectedFileItem = unstagedFile
            }
            // If not found by ID, try to find by path
            else if let selectedPath = selectedFileItem?.fromFilePath {
                if let stagedFile = stagedFiles.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileItem = stagedFile
                } else if let unstagedFile = unstagedFiles.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileItem = unstagedFile
                }
                // Use toFilePath as fallback for added files
                else if let toPath = selectedFileItem?.toFilePath, !toPath.isEmpty {
                    if let stagedFile = stagedFiles.first(where: { $0.toFilePath == toPath }) {
                        selectedFileItem = stagedFile
                    } else if let unstagedFile = unstagedFiles.first(where: { $0.toFilePath == toPath }) {
                        selectedFileItem = unstagedFile
                    }
                }
            }
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedFiles, id: \.status) { group in
                        ForEach(group.files, id: \.fromFilePath) { file in
                            ModernFileRow(
                                fileDiff: file,
                                isSelected: selectedFile?.fromFilePath == file.fromFilePath,
                                actionIcon: actionIcon,
                                actionColor: actionColor,
                                action: { action(file) },
                                onStage: onStage != nil ? { onStage?(file) } : nil,
                                onUnstage: onUnstage != nil ? { onUnstage?(file) } : nil,
                                onReset: onReset != nil ? { onReset?(file) } : nil,
                                onIgnore: onIgnore != nil ? { onIgnore?(file) } : nil,
                                onTrash: onTrash != nil ? { onTrash?(file) } : nil,
                                isStaged: isStaged
                            )
                            .onTapGesture { selectedFile = file }
                            .onAppear {
                                // Track visible files
                                visibleFiles.insert(file.fromFilePath)
                            }
                            .onDisappear {
                                // Remove from tracking when not visible
                                visibleFiles.remove(file.fromFilePath)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 300) // Limit height for better performance
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

