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

    private let templates = CommitTemplate.defaultTemplates

    var body: some View {
        VStack(spacing: 0) {
            headerView
            textEditorView.padding(.bottom, 8)
            footerView
        }
        .background(backgroundStyle)
        .padding(.top, 6)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "pencil.and.outline")
                .accessibilityHidden(true)
            Text("Commit Message")
                .font(.headline)
            if stagedCount > 0 {
                stagedCountBadge
            }
            Spacer()
            templatesMenu
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }

    private var stagedCountBadge: some View {
        Text("\(stagedCount)")
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityLabel("\(stagedCount) files staged")
    }

    private var templatesMenu: some View {
        Menu {
            ForEach(templates) { template in
                Button(template.shortTitle) {
                    commitMessage = template.content
                }
            }
        } label: {
            Label("Templates", systemImage: "doc.text")
                .labelStyle(.iconOnly)
                .padding(.horizontal, 4)
        }
        .menuStyle(.borderlessButton)
    }

    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $commitMessage)
                .font(.system(size: 15, design: .monospaced))
                .frame(height: 90)
                .padding(10)
                .background(Material.ultraThin)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            if commitMessage.isEmpty {
                placeholderTextView
            }
        }
    }

    private var placeholderTextView: some View {
        Text("Enter a descriptive commit message...")
            .foregroundStyle(.secondary)
            .padding(.top, 18)
            .padding(.leading, 24)
            .font(.system(size: 15, design: .monospaced))
            .allowsHitTesting(false)
    }

    private var footerView: some View {
        HStack {
            if showError {
                errorLabel
            }
            Spacer()
            commitButtonView
        }
        .padding(.bottom, 12)
    }

    private var errorLabel: some View {
        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .font(.caption)
            .padding(.leading, 16)
    }

    private var commitButtonView: some View {
        Button(action: handleCommit) {
            if isCommitting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 20, height: 20)
            } else {
                Label("Commit", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isCommitButtonDisabled)
        .padding(.trailing, 16)
        .keyboardShortcut(.return, modifiers: .command)
    }

    private var isCommitButtonDisabled: Bool {
        commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCommitting
    }

    private func handleCommit() {
        if commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Commit message cannot be empty."
            showError = true
            return
        }
        showError = false
        onCommit()
    }

    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(.controlBackgroundColor))
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
}

// Example CommitTemplate structure (should be defined elsewhere, e.g., in Models)
struct CommitTemplate: Identifiable {
    let id = UUID()
    let shortTitle: String
    let content: String

    static let defaultTemplates = [
        CommitTemplate(shortTitle: "Feature", content: "feat: <description>\n\n[optional body]"),
        CommitTemplate(shortTitle: "Fix", content: "fix: <description>\n\n[optional body]"),
        CommitTemplate(shortTitle: "Chore", content: "chore: <description>\n\n[optional body]"),
        CommitTemplate(shortTitle: "Docs", content: "docs: <description>\n\n[optional body]")
    ]
}

// Ensure that types like `CommitTemplate` are properly defined and accessible.
