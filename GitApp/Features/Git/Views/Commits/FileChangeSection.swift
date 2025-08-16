import SwiftUI

// Component to display file changes in commit details
//
//  FileChangeSection.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct FileChangeSection: View {
    let fileDiff: FileDiff
     var viewModel: GitViewModel
    @State private var isExpanded: Bool
    @State private var language: Language = .other
    var showBlameInfo: Bool = false

    init(fileDiff: FileDiff, viewModel: GitViewModel, isExpanded: Bool = false, showBlameInfo: Bool = false) {
        self.fileDiff = fileDiff
        self.viewModel = viewModel
        self._isExpanded = State(initialValue: isExpanded)
        self.showBlameInfo = showBlameInfo
    }

    private var statusColor: Color {
        return fileDiff.status.color
    }

    private var statusIcon: String {
        return fileDiff.status.icon
    }

    private var blameInfo: [Int: BlameLine]? {
        // Get blame info for this file if available
        let filePath = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
        return viewModel.fileBlameInfo[filePath]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky header
            fileHeader
                .background(Color(.windowBackgroundColor))
                .zIndex(1)

            if isExpanded {
                // Chunks
                LazyVStack(spacing: 0) {
                    ForEach(fileDiff.chunks) { chunk in
                        ChunkView(
                            chunk: chunk,
                            blameInfo: showBlameInfo ? blameInfo : nil,
                            onBlameSelected: { commitHash in
                                if let commit = viewModel.commits.first(where: { $0.hash == commitHash }) {
                                    viewModel.selectedCommit = commit
                                    viewModel.loadCommitDetails(commit)
                                }
                            }
                        )
                    }
                }
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .task {
            // Load language based on file extension
            let fileExtension = (fileDiff.filePathDisplay as NSString).pathExtension
            language = Language.language(for: fileExtension)

            // Preload blame info if needed
            if showBlameInfo {
                let filePath = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                Task {
                    _ = await viewModel.getBlameForFile(filePath: filePath)
                }
            }
        }
    }

    private var fileHeader: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            Text(fileDiff.fromFilePath)
                .font(.headline)
            Spacer()

            // Blame indicator if enabled
            if showBlameInfo {
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(.blue)
                    .opacity(0.8)
            }

            // Open file button
            Button(action: {
                openFile()
            }) {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open file in default editor")

            Text(fileDiff.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    private func openFile() {
        guard let url = viewModel.repositoryURL else { return }
        let fileURL = url.appendingPathComponent(fileDiff.filePathDisplay)
        NSWorkspace.shared.open(fileURL)
    }
}

struct ChunkView: View {
    let chunk: Chunk
    var blameInfo: [Int: BlameLine]?
    var onBlameSelected: ((String) -> Void)?

    private var enumeratedLines: [(offset: Int, element: Line)] {
        Array(chunk.lines.enumerated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chunk header
            HStack {
                Text(chunk.raw.components(separatedBy: "\n").first ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Lines
            LazyVStack(spacing: 0) {
                ForEach(enumeratedLines, id: \.element.id) { index, line in
                    LineView(
                        line: line,
                        isAdded: line.kind == .added,
                        isRemoved: line.kind == .removed,
                        blameInfo: blameInfo != nil && line.toFileLineNumber != nil ? blameInfo?[line.toFileLineNumber!] : nil,
                        onBlameSelected: onBlameSelected
                    )
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct LineView: View {
    let line: Line
    let isAdded: Bool
    let isRemoved: Bool
    let blameInfo: BlameLine?
    var onBlameSelected: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number
            Text(line.toFileLineNumber != nil ? "\(line.toFileLineNumber!)" : "")
                .frame(width: 40, alignment: .trailing)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)

            // Line content
            Text(line.raw)
                .font(.system(.body, design: .monospaced))
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(lineBackground)

            // Blame info if available
            if let blame = blameInfo, !isAdded, !isRemoved {
                LineBlameView(
                    author: blame.author,
                    commitHash: blame.commitHash,
                    date: blame.date,
                    onTap: {
                        onBlameSelected?(blame.commitHash)
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    private var lineBackground: Color {
        if isAdded {
            return Color.green.opacity(0.2)
        } else if isRemoved {
            return Color.red.opacity(0.2)
        }
        return .clear
    }
}
