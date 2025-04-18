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

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $commitMessage)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )

                List {
                    Section("Staged Changes") {
                        ForEach(viewModel.stagedChanges) { file in
                            HStack {
                                Text(file.name)
                                Spacer()
                                Text("\(file.stagedChanges.count) changes")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Commit Changes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Commit") {
                        Task {
                            await viewModel.commitChanges(message: commitMessage)                            
                        }
                        dismiss()
                    }
                    .disabled(commitMessage.isEmpty)
                }
            }
        }
    }
}
