import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    var viewModel: PullRequestViewModel // To access comments, files, and loading states

    @State private var selectedTab: Int = 0 // 0: Description, 1: Comments, 2: Files

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main PR Info Header
            prInfoHeader
                .padding()

            Picker("Details", selection: $selectedTab) {
                Text("Description").tag(0)
                Text("Comments (\(viewModel.comments.count))").tag(1)
                Text("Files (\(viewModel.files.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Content based on selection
            // Using a switch or if/else for content for clarity instead of hidden TabView pages
            // if using TabView for its page-swipe gesture on iOS, that's fine too.
            // For macOS, a direct content switch is often cleaner for non-document tabs.

            switch selectedTab {
            case 0:
                descriptionView
            case 1:
                commentsView
            case 2:
                filesView
            default:
                EmptyView()
            }
            if let url = URL(string: pullRequest.htmlUrl) {
                Link(destination: url) {
                    Image(systemName: "safari")
                    Text("Open on Provider") // Generic term
                }
            }
            Spacer() // Ensure content pushes up if it's short
        }
    }

    private var prInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pullRequest.title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                // Re-use logic/presentation from PullRequestRow if possible, or define here
                Image(systemName: PullRequestRow(pullRequest: pullRequest).pullRequest.prStatusIconName)
                    .foregroundColor(PullRequestRow(pullRequest: pullRequest).pullRequest.prStatusColor)
                Text(pullRequest.prState.displayName)
                Text("by \(pullRequest.user.login) · Opened \(pullRequest.createdAt, style: .date)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let mergedAt = pullRequest.mergedAt {
                Text("Merged: \(mergedAt, style: .date)")
                    .font(.caption).foregroundColor(.purple)
            } else if let closedAt = pullRequest.closedAt {
                Text("Closed: \(closedAt, style: .date)")
                    .font(.caption).foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        ScrollView {
            if let body = pullRequest.body, !body.isEmpty {
                // For actual Markdown rendering, you'd use a library or Text.markdown() in newer OS versions.
                // Text(LocalizedStringKey(body)) // LocalizedStringKey is for localizable strings, not Markdown directly.
                // Using simple Text for now, assuming body is plain or will be handled by a future Markdown view.
                Text(body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                Text("No description provided.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    @ViewBuilder
    private var commentsView: some View {
        Group { // Use Group to allow conditional ProgressView or List
            if viewModel.isLoadingDetails && viewModel.comments.isEmpty {
                ProgressView("Loading Comments...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                Text("No comments yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(viewModel.comments) { comment in
                    PullRequestCommentView(comment: comment)
                }
            }
        }
    }

    @ViewBuilder
    private var filesView: some View {
        Group {
            if viewModel.isLoadingDetails && viewModel.files.isEmpty {
                ProgressView("Loading Files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                Text("No changed files in this pull request.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(viewModel.files) { file in
                    PullRequestFileView(file: file)
                }
            }
        }
    }
}

// Inline definitions of PullRequestCommentView and PullRequestFileView are removed as they are in separate files.

// Preview requires mocks
#if DEBUG
//@MainActor // Ensure preview struct runs on main actor if it involves @Observable types directly
//struct PullRequestDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockAuthor = PullRequestAuthor(id: 1, login: "octocat", avatarUrl: "https://avatars.githubusercontent.com/u/583231?v=4", htmlUrl: "")
//        let samplePR = PullRequest(
//            id: 1, number: 123, title: "Feature: Super Cool New Thing",
//            user: mockAuthor, state: "open",
//            body: "This is a **great** new feature.\n\n- Item 1\n- Item 2\n\nIt fixes #42. This is a longer body to test scrolling. It includes multiple paragraphs and hopefully will demonstrate how the text selection and markdown rendering (if implemented) would look. We need enough text to make the ScrollView actually scrollable to ensure that part of the UI is behaving as expected. More text, more text, more text. And then some more.",
//            createdAt: Date().addingTimeInterval(-172800), updatedAt: Date().addingTimeInterval(-86400),
//            closedAt: nil, mergedAt: nil,
//            htmlUrl: "https://github.com", diffUrl: "", patchUrl: "", commentsUrl: ""
//        )
//
//        // Assuming Account.User can be represented by PullRequestAuthor for simplicity
//        let mockAccount = Account(id: UUID(), provider: "GitHub", username: "previewUser", token: "token", avatarUrl: nil, user: mockAuthor, organizations: [])
//        let mockRepoOwner = GitHubUser(login: "mockOwner", id: 1, nodeId: "", avatarUrl: nil, name: nil, email: nil, company: nil, location: nil, bio: nil, publicRepos: 0, followers: 0, following: 0, createdAt: Date(), updatedAt: Date())
//        let mockRepo = GitHubRepository(id: 1, nodeId: "", name: "CoolRepo", fullName: "mockOwner/CoolRepo", isPrivate: false, owner: mockRepoOwner, htmlUrl: "", description: nil, fork: false, url: "", createdAt: Date(), updatedAt: Date(), pushedAt: Date(), homepage: nil, language: nil, forksCount: 0, stargazersCount: 0, watchersCount: 0, openIssuesCount: 0, defaultBranch: "main", license: nil)
//
//        class MockGitProviderServiceDetail: GitProviderService {
//            override func fetchPullRequestComments(owner: String, repoName: String, prNumber: Int, account: Account, page: Int, perPage: Int) async throws -> [PullRequestComment] {
//                try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
//                return [
//                    PullRequestComment(id: 1, user: mockAuthor, body: "This looks great! Consider adding more tests for edge cases.", createdAt: Date().addingTimeInterval(-36000), updatedAt: Date(), htmlUrl: "https://github.com"),
//                    PullRequestComment(id: 2, user: PullRequestAuthor(id: 2, login: "anotherUser", avatarUrl: nil, htmlUrl: nil), body: "One small suggestion regarding the naming convention in `MyClass.swift`. Otherwise, LGTM! 👍", createdAt: Date().addingTimeInterval(-18000), updatedAt: Date(), htmlUrl: "https://github.com")
//                ]
//            }
//            override func fetchPullRequestFiles(owner: String, repoName: String, prNumber: Int, account: Account, page: Int, perPage: Int) async throws -> [PullRequestFile] {
//                try await Task.sleep(nanoseconds: 700_000_000) // Simulate network delay
//                return [
//                    PullRequestFile(sha: "1abc", filename: "Sources/App/Controllers/FeatureController.swift", status: "modified", additions: 25, deletions: 5, changes: 30, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: "@@ -10,2 +10,3 @@ line1\n-old line\n+new line\n+another new line", previousFilename: nil),
//                    PullRequestFile(sha: "2def", filename: "Tests/AppTests/FeatureControllerTests.swift", status: "added", additions: 80, deletions: 0, changes: 80, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: "+ many new test lines...", previousFilename: nil),
//                    PullRequestFile(sha: "3ghi", filename: "README.md", status: "removed", additions: 0, deletions: 12, changes: 12, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: "- old readme content", previousFilename: nil)
//                ]
//            }
//        }
//
//        struct PreviewWrapper: View {
//            @State var viewModel: PullRequestViewModel
//            let pr: PullRequest
//            init(pr: PullRequest) {
//                self.pr = pr
//                let service = MockGitProviderServiceDetail()
//                self._viewModel = State(initialValue: PullRequestViewModel(gitProviderService: service, account: mockAccount, repository: mockRepo))
//            }
//            var body: some View {
//                PullRequestDetailView(pullRequest: pr, viewModel: viewModel)
//                    .task {
//                        // Select the PR to trigger data loading in the ViewModel for the preview
//                        await viewModel.selectPullRequest(pr)
//                    }
//            }
//        }
//
//        return NavigationView {
//            PreviewWrapper(pr: samplePR)
//        }
//        .previewDisplayName("Pull Request Detail")
//    }
//}
#endif
