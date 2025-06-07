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
    var onResolveWithMine: ((FileDiff) -> Void)? = nil
    var onResolveWithTheirs: ((FileDiff) -> Void)? = nil
    var isStaged: Bool = false
    var showUntrackedFiles: Bool = true

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
//                        Section(header: FileStatusHeader(status: group.status, count: group.files.count)) {
                            ForEach(group.files, id: \ .fromFilePath) { file in
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
                                    onResolveWithMine: onResolveWithMine != nil ? { onResolveWithMine?(file) } : nil,
                                    onResolveWithTheirs: onResolveWithTheirs != nil ? { onResolveWithTheirs?(file) } : nil,
                                    isStaged: isStaged
                                )
                                .onTapGesture { selectedFile = file }
                            }
//                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

