//
//  CloneRepositoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI

struct CloneRepositoryView: View {
    @Bindable var viewModel: RepositoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cloneURL: String = ""
    @State private var selectedDirectory: URL?
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""
    @State private var extractedRepoName: String?

    private var isValidURL: Bool {
        guard !cloneURL.isEmpty else { return false }
        return cloneURL.hasPrefix("https://") || cloneURL.hasPrefix("git@")
    }

    private var canClone: Bool {
        isValidURL && selectedDirectory != nil && !viewModel.isCloning
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Repository URL") {
                    TextField("https://github.com/username/repo.git", text: $cloneURL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
//                        .textInputAutocapitalization(.never)
                        .onChange(of: cloneURL) { _ in
                            extractRepoName()
                        }

                    if let repoName = extractedRepoName {
                        Label("Repository: \(repoName)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("Clone Location") {
                    if let directory = selectedDirectory {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(directory.path)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Choose Directory") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false

                        if panel.runModal() == .OK, let url = panel.url {
                            selectedDirectory = url
                        }
                    }
                }

                if viewModel.isCloning {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: viewModel.cloneProgress)
                                .progressViewStyle(.linear)
                            Text(viewModel.cloneStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Clone Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        cloneRepository()
                    }
                    .disabled(!canClone)
                }
            }
            .alert("Error", isPresented: $isShowingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }

    private func extractRepoName() {
        guard isValidURL else {
            extractedRepoName = nil
            return
        }

        // Extract repository name from URL
        if let lastComponent = cloneURL.components(separatedBy: "/").last?
            .replacingOccurrences(of: ".git", with: "") {
            extractedRepoName = lastComponent
        }
    }

    private func cloneRepository() {
        guard let directory = selectedDirectory else {
            errorMessage = "Please select a directory to clone into"
            isShowingErrorAlert = true
            return
        }

        Task {
            do {
                if try await viewModel.cloneRepository(from: cloneURL, to: directory) {
                    // Show success feedback
                    viewModel.errorMessage = "Repository cloned successfully"
                    dismiss()
                }
            } catch {
                errorMessage = "Clone failed: \(error.localizedDescription)"
                isShowingErrorAlert = true
            }
        }
    }
}
