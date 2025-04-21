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
    let viewModel: GitViewModel
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
                .background(Color(.windowBackgroundColor))
                .zIndex(1)

            if isExpanded {
                // Chunks
                LazyVStack(spacing: 0) {
                    ForEach(fileDiff.chunks) { chunk in
                        ChunkView(
                            chunk: chunk,
                            language: language,
                            onStage: { viewModel.stageChunk(chunk, in: fileDiff) },
                            onUnstage: { viewModel.unstageChunk(chunk, in: fileDiff) },
                            onReset: { viewModel.resetChunk(chunk, in: fileDiff) }
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
            Text(fileDiff.filePathDisplay)
                .font(.headline)
            Spacer()
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
}

struct ChunkView: View {
    let chunk: Chunk
    let language: Language
    let onStage: () -> Void
    let onUnstage: () -> Void
    let onReset: () -> Void

    private var enumeratedLines: [(offset: Int, element: Chunk.Line)] {
        Array(chunk.lines.enumerated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chunk header
            HStack {
                Text(chunk.raw.components(separatedBy: "\n").first ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: onStage) {
                        Label("Stage", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onUnstage) {
                        Label("Unstage", systemImage: "minus.circle")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onReset) {
                        Label("Reset", systemImage: "arrow.uturn.backward.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Lines
            LazyVStack(spacing: 0) {
                ForEach(enumeratedLines, id: \.element.id) { index, line in
                    LineView(
                        line: line,
                        language: language,
                        isAdded: line.kind == .added,
                        isRemoved: line.kind == .removed
                    )
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct LineView: View {
    let line: Chunk.Line
    let language: Language
    let isAdded: Bool
    let isRemoved: Bool

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
                    .foregroundColor(language.color(for: line.raw))
                    .padding(.leading, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(lineBackground)

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

