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
    @Bindable var viewModel: GitViewModel
    @State private var isExpanded: Bool
    @State private var language: Language = .other

    init(fileDiff: FileDiff, viewModel: GitViewModel, isExpanded: Bool = false) {
        self.fileDiff = fileDiff
        self.viewModel = viewModel
        self._isExpanded = State(initialValue: isExpanded)
    }

    private var statusColor: Color {
        return fileDiff.status.color
    }

    private var statusIcon: String {
        return fileDiff.status.icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky header
            fileHeader
                .background(Material.bar)
                .zIndex(1)

            if isExpanded {
                // Chunks
                LazyVStack(spacing: 0) {
                    ForEach(fileDiff.chunks) { chunk in
                        ChunkView(chunk: chunk)
                    }
                }
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .task {
            await loadLanguage()
        }
    }

    private var fileHeader: some View {
        HStack {
            InteractionButton(
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                },
                iconName: isExpanded ? "chevron.down" : "chevron.right",
                tooltip: isExpanded ? "Collapse" : "Expand"
            )

            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            Text(fileDiff.filePathDisplay)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            InteractionButton(
                action: openFile,
                iconName: "doc.text",
                tooltip: "Open file in default editor"
            )

            Text(fileDiff.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
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

    private func loadLanguage() async {
        // Load language based on file extension
        let fileExtension = (fileDiff.filePathDisplay as NSString).pathExtension
        language = Language.language(for: fileExtension)
    }

    private func openFile() {
        guard let repoURL = viewModel.repositoryURL else { return }
        let fileURL = repoURL.appendingPathComponent(fileDiff.filePathDisplay)

        // Check if the file exists before attempting to open
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.open(fileURL)
        } else {
            // Handle error: file not found
            print("Error: File not found at \(fileURL.path)")
            // Optionally, show an alert to the user
        }
    }
}

// Extracted button for reusability and clarity
private struct InteractionButton: View {
    let action: () -> Void
    let iconName: String
    let tooltip: String

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

struct ChunkView: View {
    let chunk: Chunk

    // Use direct iteration with indices for potentially better performance
    // if Line is not Identifiable or id is not stable.
    // However, if Line is Identifiable and id is stable, ForEach(chunk.lines) is fine.
    private var lines: [Line] { chunk.lines }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chunk header
            Text(chunk.header)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            // Lines
            LazyVStack(spacing: 0) {
                ForEach(lines) { line in // Assuming Line is Identifiable
                    LineView(line: line)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct LineView: View {
    let line: Line

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) { // Use .firstTextBaseline for better alignment
            // Line numbers (old and new)
            HStack(spacing: 4) {
                Text(line.toFileLineNumber != nil ? "\(line.toFileLineNumber!)" : " ")
                    .frame(width: 30, alignment: .trailing)
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)

            // Line content
            Text(line.raw)
                .font(.system(.body, design: .monospaced))
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(lineBackground)
        }
        .padding(.horizontal)
    }

    private var lineBackground: Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.2)
        case .removed: return Color.red.opacity(0.2)
        default: return .clear
        }
    }
}

// Make sure Line is Identifiable, e.g., by adding `id` property if it doesn't have one.
// extension Line: Identifiable { /* ... */ }

// Ensure FileDiff, Chunk, and Line have necessary properties like `filePathDisplay`, `header`, `content`, `kind`.
// Update these based on your actual data model structure.
