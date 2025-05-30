//
//  ModernFileListView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//
import SwiftUI

// MARK: - Modern File List View
struct ModernFileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    let actionIcon: String
    let actionColor: Color
    let action: (FileDiff) -> Void
    var onStage: ((FileDiff) -> Void)? = nil
    var onUnstage: ((FileDiff) -> Void)? = nil
    var onReset: ((FileDiff) -> Void)? = nil
    var onIgnore: ((FileDiff) -> Void)? = nil
    var onTrash: ((FileDiff) -> Void)? = nil
    var isStaged: Bool = false
    var showUntrackedFiles: Bool = true

    private var groupedFiles: [(status: FileStatus, files: [FileDiff])] {
        Dictionary(grouping: files, by: { $0.status })
            .map { (status: $0.key, files: $0.value) }
            .sorted { $0.status.rawValue < $1.status.rawValue }
    }

    var body: some View {
        if files.isEmpty {
            emptyStateView
        } else {
            fileListContentView
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
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
    }

    private var fileListContentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
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
                        .contentShape(Rectangle())
                        .onTapGesture { selectedFile = file }
                        Divider().padding(.leading, 20)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// Placeholder for FileStatusHeader if you decide to use sections
// struct FileStatusHeader: View { ... }

// Ensure FileDiff is Identifiable, e.g.:
// struct FileDiff: Identifiable { let id = UUID(); /* other properties */ }
// Ensure FileStatus is Hashable and has a comparable rawValue if used as in `groupedFiles` sorting.

