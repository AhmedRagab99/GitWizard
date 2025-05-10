//
//  CommitMessageArea.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//
import SwiftUI

// MARK: - Commit Message Area
struct CommitMessageArea: View {
    @Binding var commitMessage: String
    @Binding var isCommitting: Bool
    let stagedCount: Int
    let onCommit: () -> Void
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedTemplate: String = ""

    let templates = [
        "feat: <description>\n\n[optional body]",
        "fix: <description>\n\n[optional body]",
        "chore: <description>\n\n[optional body]",
        "docs: <description>\n\n[optional body]"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.and.outline")
                Text("Commit Message")
                    .font(.headline)
                if stagedCount > 0 {
                    Text("\(stagedCount)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.18))
                        .cornerRadius(6)
                        .accessibilityLabel("\(stagedCount) files staged")
                }
                Spacer()
                Menu {
                    ForEach(templates, id: \.self) { template in
                        Button(template.prefix(20) + "...", action: {
                            commitMessage = template
                        })
                    }
                } label: {
                    Label("Templates", systemImage: "doc.text")
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $commitMessage)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(height: 90)
                    .padding(10)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                if commitMessage.isEmpty {
                    Text("Enter a descriptive commit message...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 18)
                        .padding(.leading, 24)
                        .font(.system(size: 15, design: .monospaced))
                        .allowsHitTesting(false)
                }
            }
            .padding(.bottom, 8)
            HStack {
                if showError {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.leading, 16)
                }
                Spacer()
                Button(action: {
                    if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        errorMessage = "Commit message cannot be empty."
                        showError = true
                        return
                    }
                    showError = false
                    onCommit()
                }) {
                    if isCommitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Label("Commit", systemImage: "arrow.up.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCommitting)
                .padding(.trailing, 16)
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
        .padding(.top, 6)
        .padding(.horizontal, 0)
    }
}
