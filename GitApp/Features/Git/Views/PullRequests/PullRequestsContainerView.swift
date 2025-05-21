import SwiftUI

struct PullRequestsContainerView: View {
    var viewModel = PullRequestViewModel()
    @Bindable var gitViewModel: GitViewModel
    @State private var hasSetupRepository = false

    var body: some View {
        NavigationStack {
            PullRequestListView(viewModel: viewModel, showContentLoading: false)
//                .navigationTitle("Pull Requests")
                .navigationDestination(for: PullRequest.self) { pullRequest in
                    PullRequestDetailView(viewModel: viewModel, gitViewModel: gitViewModel, pullRequest: pullRequest)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            Task {
                                await viewModel.loadPullRequests()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        settingsButton
                    }
                }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.1))
            }
        }
        .onAppear {
            if !hasSetupRepository {
                setupRepository()
                hasSetupRepository = true
            }
        }
    }

    private var settingsButton: some View {
        Menu {
            Button(action: {
                // Show auth token setting dialog
                showTokenDialog()
            }) {
                Label("Set GitHub Token", systemImage: "key")
            }

            Button(action: {
                // Open browser to create a new PR
                if !gitViewModel.repoInfo.remoteURL.isEmpty {
                    openNewPRInBrowser(gitViewModel.repoInfo.remoteURL)
                }
            }) {
                Label("Create Pull Request", systemImage: "plus")
            }
        } label: {
            Image(systemName: "gearshape")
        }
    }

    private func setupRepository() {
        // Extract owner/repo from Git remote URL
        if !gitViewModel.repoInfo.remoteURL.isEmpty {
            viewModel.setupRepository(remoteURL: gitViewModel.repoInfo.remoteURL)

            // Get token from keychain or user defaults
            if let token = UserDefaults.standard.string(forKey: "GitHubAPIToken") {
                viewModel.setAuthToken(token)
            }

            // Load pull requests
            Task {
                await viewModel.loadPullRequests()
            }
        }
    }

    // MARK: - Actions

    private func showTokenDialog() {
        let alert = NSAlert()
        alert.messageText = "GitHub API Token"
        alert.informativeText = "Enter your GitHub personal access token to access private repositories and higher rate limits."

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "GitHub token"

        // Set current token if available
        if let token = UserDefaults.standard.string(forKey: "GitHubAPIToken") {
            textField.stringValue = token
        }

        alert.accessoryView = textField
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let token = textField.stringValue

            // Save token to UserDefaults (in a real app, use Keychain)
            UserDefaults.standard.set(token, forKey: "GitHubAPIToken")

            // Update viewModel with token
            viewModel.setAuthToken(token)

            // Reload pull requests with new token
            Task {
                await viewModel.loadPullRequests()
            }
        }
    }

    private func openNewPRInBrowser(_ remoteURL: String) {
        guard let extractedInfo = viewModel.githubService.extractOwnerAndRepo(from: remoteURL),
              let url = URL(string: "https://github.com/\(extractedInfo.owner)/\(extractedInfo.repo)/compare") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

// MARK: - Previews

#Preview {
    PullRequestsContainerView(gitViewModel: GitViewModel())
}
