//
//  CloneRepositoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI

struct CloneRepositoryView: View {
    @Environment(\.dismiss) var dismiss
    @State var viewModel: RepositoryViewModel
    @Bindable var accountManager: AccountManager

    @State private var repositoryURL: String
    @State private var destinationPath: String = CloneRepositoryView.defaultPath()
    @State private var selectedAccount: Account?
    @State private var isShowingFileImporter = false
    @State private var isCloning = false
    @State private var cloneError: String?

    init(viewModel: RepositoryViewModel, accountManager: AccountManager, initialCloneURL: String = "") {
        self.viewModel = viewModel
        self.accountManager = accountManager
        self._repositoryURL = State(initialValue: initialCloneURL)
        self._destinationPath = State(initialValue: Self.defaultPath())

        if !initialCloneURL.isEmpty {
            self._selectedAccount = State(initialValue: accountManager.accounts.first { acc in
                guard let serverURLString = acc.serverURL, !serverURLString.isEmpty,
                      let serverURL = URL(string: serverURLString),
                      let repoHost = URL(string: initialCloneURL)?.host else {
                    return initialCloneURL.lowercased().contains("github.com") && acc.type == .githubCom
                }
                return serverURL.host?.lowercased() == repoHost.lowercased() && acc.type == (repoHost.lowercased().contains("github.com") ? .githubCom : .githubEnterprise)
            } ?? accountManager.accounts.first(where: { $0.type == .githubCom && initialCloneURL.lowercased().contains("github.com") }))
        } else {
             self._selectedAccount = State(initialValue: accountManager.accounts.first)
        }
    }

    var body: some View {
        
            Form {
                Section("Repository Details") {
                    TextField("Git Repository URL (HTTPS or SSH)", text: $repositoryURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: repositoryURL) { _, newValue in
                            selectedAccount = accountManager.accounts.first { acc in
                                guard let serverURLString = acc.serverURL, !serverURLString.isEmpty,
                                      let serverURL = URL(string: serverURLString),
                                      let repoHost = URL(string: newValue)?.host else {
                                    return newValue.lowercased().contains("github.com") && acc.type == .githubCom
                                }
                                return serverURL.host?.lowercased() == repoHost.lowercased() && acc.type == (repoHost.lowercased().contains("github.com") ? .githubCom : .githubEnterprise)
                            } ?? accountManager.accounts.first(where: { $0.type == .githubCom && newValue.lowercased().contains("github.com") })
                        }

                    Picker("Account (Optional)", selection: $selectedAccount) {
                        Text("None").tag(nil as Account?)
                        ForEach(accountManager.accounts) { account in
                            Text(account.displayName).tag(account as Account?)
                        }
                    }
                }

                Section("Clone Location") {
                    HStack {
                        TextField("Local Path", text: $destinationPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(true)
                        Button {
                            isShowingFileImporter = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .buttonStyle(.borderless)
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
                    .disabled(repositoryURL.isEmpty)
                }
            }
        .frame(minWidth: 400, minHeight: 200)
        .padding()
        .errorAlert(cloneError ?? viewModel.errorMessage)
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    destinationPath = url.path
                }
            case .failure(let error):
                cloneError = "Failed to select directory: \(error.localizedDescription)"
            }
        }
    }

    private static func defaultPath() -> String {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsURL.appendingPathComponent("GitAppClones").path
        }
        return ""
    }

    private func cloneRepository() {
        guard !repositoryURL.isEmpty else {
            cloneError = "Repository URL cannot be empty."
            return
        }
        guard !destinationPath.isEmpty, let destinationURL = URL(string: "file://\(destinationPath)") else {
            cloneError = "Invalid or empty destination path."
            return
        }

        isCloning = true
        cloneError = nil

        Task {
            do {
                let success = try await viewModel.cloneRepository(from: repositoryURL, to: destinationURL)
                await MainActor.run {
                    isCloning = false
                    if success {
                        dismiss()
                    } else {
                        cloneError = viewModel.errorMessage ?? "Cloning failed. Check repository URL and permissions."
                    }
                }
            } catch {
                await MainActor.run {
                    isCloning = false
                    cloneError = error.localizedDescription
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
