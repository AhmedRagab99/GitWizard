//
//  CommitSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI

struct CommitSheet: View {
    @ObservedObject var viewModel: GitViewModel
    @Binding var commitMessage: String
    @Environment(\.dismiss) private var dismiss

    private var stagedFiles: [FileDiff] {
        viewModel.stagedDiff?.fileDiffs ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                commitMessageEditor
                stagedChangesList
            }
            .padding()
            .navigationTitle("Commit Changes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    commitButton
                }
            }
        }
    }

    private var commitMessageEditor: some View {
        TextEditor(text: $commitMessage)
            .font(.system(.body, design: .monospaced))
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2))
            )
    }

    private var stagedChangesList: some View {
        List {
            Section("Staged Changes") {
                ForEach(stagedFiles) { file in
                    StagedFileRow(file: file)
                }
            }
        }
    }

    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }

    private var commitButton: some View {
        Button("Commit") {
            Task {
                await viewModel.commitChanges(message: commitMessage)
            }
            dismiss()
        }
        .disabled(commitMessage.isEmpty)
    }
}

// MARK: - Row Views
struct StagedFileRow: View {
    let file: FileDiff

    var body: some View {
        HStack {
            Text(file.header)
            Spacer()
            Text("\(file.chunks.count) changes")
                .foregroundStyle(.secondary)
        }
    }
}
