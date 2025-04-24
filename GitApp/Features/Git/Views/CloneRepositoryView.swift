//
//  CloneRepositoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI

struct CloneRepositoryView: View {
     var viewModel: GitViewModel
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

struct ImportRepositoryView: View {
     var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?

    var body: some View {
        NavigationStack {
            VStack {
                if let url = selectedURL {
                    Text(url.path)
                        .foregroundStyle(.secondary)
                        .padding()
                }

                Button("Choose Repository") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false

                    if panel.runModal() == .OK {
                        selectedURL = panel.url
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Import Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        if let url = selectedURL {
                            viewModel.importRepository(from: url)
                        } else {
                            viewModel.errorMessage = "Please select a Git repository"
                        }
                    }
                    .disabled(selectedURL == nil)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }
}

struct AddLocalRepositoryView: View {
     var viewModel: GitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?
    @State private var isGitRepo: Bool = false
    @State private var branchInfo: String?
    @State private var remoteInfo: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let url = selectedURL {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                Text(url.path)
                                    .foregroundStyle(.secondary)
                            }

                            if isGitRepo {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Valid Git Repository", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)

                                    if let branch = branchInfo {
                                        HStack {
                                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                                .foregroundStyle(.secondary)
                                            Text("Current Branch: \(branch)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !remoteInfo.isEmpty {
                                        Text("Remotes:")
                                            .font(.headline)
                                        ForEach(remoteInfo, id: \.self) { remote in
                                            HStack {
                                                Image(systemName: "arrow.triangle.branch")
                                                    .foregroundStyle(.secondary)
                                                Text(remote)
                                                    .font(.system(.body, design: .monospaced))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            } else {
                                Label("Not a Git Repository", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Button("Choose Repository") {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false

                            if panel.runModal() == .OK {
                                selectedURL = panel.url
                                updateRepositoryInfo()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Local Repository")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let url = selectedURL {
                            Task {
                                await viewModel.addLocalRepository(at: url)
                            }
                        }
                    }
                    .disabled(selectedURL == nil || viewModel.isImporting || !isGitRepo)
                }
            }
            .overlay {
                if viewModel.isImporting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        if let progress = viewModel.importProgress {
                            VStack(spacing: 8) {
                                ProgressView(value: Double(progress.current), total: Double(progress.total))
                                    .progressViewStyle(.linear)

                                Text(progress.status)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 200)
                        }

                        Text(viewModel.importStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    private func updateRepositoryInfo() {
        guard let url = selectedURL else { return }

        Task {
            // Check if it's a Git repository
            isGitRepo = await viewModel.isGitRepository(at: url)

            if isGitRepo {
                // Get current branch
                if let branchResult = await viewModel.currentBranch {
                    branchInfo = branchResult.name.trimmingCharacters(in: .whitespacesAndNewlines)
                }

//                // Get remote information
                 let remotes =  viewModel.repoInfo
                    remoteInfo = remotes.remotes.map({return $0.name})

            } else {
                branchInfo = nil
                remoteInfo = []
            }
        }
    }
}
