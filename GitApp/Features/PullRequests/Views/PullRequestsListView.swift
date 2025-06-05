import SwiftUI

struct PullRequestsListView: View {
    @Bindable var viewModel: PullRequestViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // Header and Filter
            headerView

            if viewModel.isLoadingPullRequests && viewModel.pullRequests.isEmpty {
                ProgressView("Loading Pull Requests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.pullRequests.isEmpty {
                VStack {
                    Text("Error")
                        .font(.title)
                    Text(errorMessage)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.loadPullRequests(refresh: true)
                        }
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pullRequests.isEmpty {
                Text("No pull requests found for the current filter.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                listContentView
            }
        }
        .onChange(of: viewModel.selectedPullRequest) { oldValue, newValue in
            guard let selectedPR = newValue else { return }

            Task {
                await viewModel.selectPullRequest(selectedPR)


                // Generate a unique ID for the window to allow for multiple PR detail windows
                // and to potentially reopen/focus existing ones if desired (though openNewWindow creates a new one or brings existing to front based on ID).
                let windowId = "pull-request-detail-\(selectedPR.id)-\(selectedPR.number)"
                let windowTitle = "PR #\(selectedPR.number): \(selectedPR.title)"

                openNewWindow(
                    with: PullRequestDetailView(pullRequest: selectedPR, viewModel: viewModel),
                    id: windowId,
                    title: windowTitle,
                    width: 800, // Adjust width as needed
                    height: 600 // Adjust height as needed
                )
            }            
             viewModel.selectedPullRequest = nil
            
        }
        .toolbar {
            ToolbarItem(placement: .automatic) { // Or .navigationBarTrailing for macOS
                Button {
                    Task {
                        await viewModel.loadPullRequests(refresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoadingPullRequests)
            }
        }
        .task {
            if viewModel.pullRequests.isEmpty {
                await viewModel.loadPullRequests()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Filter by:")
            Picker("Filter Pull Requests", selection: $viewModel.currentFilterState) {
                ForEach(PullRequestState.allCases) { state in
                    Text(state.displayName).tag(state)
                }
            }
            .pickerStyle(.segmented) // Or .menu for more options / macOS HIG
            .labelsHidden()
            Spacer()
        }
        .padding()
    }

    private var listContentView: some View {
        List(selection: $viewModel.selectedPullRequest) {
            ForEach(viewModel.pullRequests) { pr in
                PullRequestRow(pullRequest: pr)
                    .tag(pr)
                    .task {
                        if pr.id == viewModel.pullRequests.last?.id && viewModel.canLoadMorePullRequests && !viewModel.isLoadingPullRequests {
                            await viewModel.loadPullRequests()
                        }
                    }
            }

            if viewModel.isLoadingPullRequests && !viewModel.pullRequests.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if !viewModel.canLoadMorePullRequests && !viewModel.pullRequests.isEmpty {
                 Text("No more pull requests.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .listStyle(.inset) // Or .plain for macOS
    }
}

// Preview needs a mock ViewModel, Account, and GitHubRepository
#if DEBUG
//@MainActor // Ensure preview struct runs on main actor if it involves @Observable types directly
//struct PullRequestsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Mock Account
//        let mockLoginAuthor = PullRequestAuthor(id: 1, login: "user", avatarUrl: nil, htmlUrl: nil)
//        // For Account model, ensure user parameter can take PullRequestAuthor or adapt Account model if it expects a different User type.
//        // Assuming Account.User can be represented by PullRequestAuthor for simplicity in preview, or use a more specific GitHubUser if Account model requires it.
//        let mockAccount = Account(id: UUID(), provider: "GitHub", username: "mockUser", token: "mockToken", avatarUrl: nil, user: mockLoginAuthor, organizations: [])
//
//        // Mock GitHubRepository
//        let mockRepoOwner = GitHubUser(login: "mockOwner", id: 1, nodeId: "node", avatarUrl: nil, name: "Mock Owner", email: nil, company: nil, location: nil, bio: nil, publicRepos: 1, followers: 0, following: 0, createdAt: Date(), updatedAt: Date())
//        let mockRepo = GitHubRepository(id: 1, nodeId: "repoNode", name: "SampleRepo", fullName: "mockOwner/SampleRepo", isPrivate: false, owner: mockRepoOwner, htmlUrl: "", description: "A sample repository", fork: false, url: "", createdAt: Date(), updatedAt: Date(), pushedAt: Date(), homepage: nil, language: "Swift", forksCount: 0, stargazersCount: 0, watchersCount: 0, openIssuesCount: 5, defaultBranch: "main", license: nil)
//
//        // Mock GitProviderService
//        class MockGitProviderService: GitProviderService {
//            override func fetchPullRequests(owner: String, repoName: String, account: Account, state: PullRequestState, page: Int, perPage: Int) async throws -> [PullRequest] {
//                let author = PullRequestAuthor(id: 1, login: "octocat", avatarUrl: nil, htmlUrl: nil)
//                let pr1 = PullRequest(id: 1, number: 1, title: "First PR", user: author, state: "open", body: "Body1", createdAt: Date(), updatedAt: Date(), closedAt: nil, mergedAt: nil, htmlUrl: "", diffUrl: "", patchUrl: "", commentsUrl: "")
//                let pr2 = PullRequest(id: 2, number: 2, title: "Second PR", user: author, state: "closed", body: "Body2", createdAt: Date(), updatedAt: Date(), closedAt: Date(), mergedAt: nil, htmlUrl: "", diffUrl: "", patchUrl: "", commentsUrl: "")
//                if page > 1 { return [] }
//
//                var results = [pr1, pr2]
//                if state != .all {
//                    results = results.filter { $0.prState == state }
//                }
//                return results
//            }
//        }
//
//        let mockService = MockGitProviderService()
//        // The ViewModel should be created as @State here for the preview to own it.
//        // However, the view itself defines `var viewModel`, expecting it to be passed.
//        // For previews, we can wrap it in a struct that holds it as state.
//        struct PreviewWrapper: View {
//            @State var viewModel: PullRequestViewModel
//            init() {
//                _viewModel = State(initialValue: PullRequestViewModel(gitProviderService: mockService, account: mockAccount, repository: mockRepo))
//            }
//            var body: some View {
//                PullRequestsListView(viewModel: viewModel)
//            }
//        }
//
//        return NavigationView {
//            PreviewWrapper()
//        }
//        .previewDisplayName("Pull Requests List")
//    }
//}
#endif
