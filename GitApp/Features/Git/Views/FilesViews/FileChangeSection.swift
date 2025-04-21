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

    private var statusColor: Color {
        return fileDiff.status.color
    }

    private var statusIcon: String {
        return fileDiff.status.icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // File header
            HStack {
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
            .padding(.top, 8)

            // Chunks
            ForEach(fileDiff.chunks) { chunk in
                ChunkView(
                    chunk: chunk,
                    onStage: { viewModel.stageChunk(chunk, in: fileDiff) },
                    onUnstage: { viewModel.unstageChunk(chunk, in: fileDiff) },
                    onReset: { viewModel.resetChunk(chunk, in: fileDiff) }
                )
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ChunkView: View {
    let chunk: Chunk
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
                Text(chunk.stageString)
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
            ForEach(enumeratedLines, id: \.element.id) { index, line in
                HStack(alignment: .top, spacing: 0) {
                    // Line number
                    Text(line.toFileLineNumber != nil ? "\(line.toFileLineNumber!)" : "")
                        .frame(width: 40, alignment: .trailing)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)

                    // Line content
                    Text(line.raw)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(line.kind == .added ? .green : line.kind == .removed ? .red : .primary)
                        .padding(.leading, 8)
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
}

