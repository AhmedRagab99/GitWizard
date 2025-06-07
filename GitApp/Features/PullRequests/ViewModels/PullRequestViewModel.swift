import Foundation

@Observable
class PullRequestViewModel  {
    // MARK: - Constants
    private let pullRequestsPerPage = 20
    private let commentsPerPage = 30
    private let reviewCommentsPerPage = 30
    private let filesPerPage = 30 // GitHub API default for files is 30, max 100.

    // MARK: - Properties for Listing/Viewing PRs
    var pullRequests: [PullRequest] = []
    var comments: [PullRequestComment] = []
    var reviewComments: [PullRequestComment] = [] // This will be deprecated in favor of lineCommentsByFile
    var lineCommentsByFile: [String: [PullRequestComment]] = [:]
    var files: [PullRequestFile] = []
    var reviews: [PullRequestReview] = []
    var selectedPullRequest: PullRequest? {
        didSet {
            // Data loading is now primarily handled in selectPullRequest method
        }
    }

    // MARK: - Loading States
    var isLoadingPullRequests = false
    var isLoadingInitialDetails = false // For the first load of all details for a selected PR
    var isLoadingMoreComments = false
    var isLoadingMoreReviewComments = false
    var isLoadingMoreFiles = false
    var isLoadingReviews = false

    // MARK: - Error Messages
    var pullRequestListError: String?
    var commentsError: String?
    var reviewCommentsError: String?
    var filesError: String?
    var reviewsError: String?
    var mergeError: String?

    var currentFilterState: PullRequestState = .open {
        didSet {
            Task {
                await loadPullRequests(refresh: true)
            }
        }
    }

    // MARK: - Pagination State for PR List
    private var currentPRListPage = 1
    var canLoadMorePullRequests = true

    // MARK: - Pagination State for Comments
    private var currentCommentsPage = 1
    var canLoadMoreComments = true

    // MARK: - Pagination State for Review Comments
    private var currentReviewCommentsPage = 1
    var canLoadMoreReviewComments = true

    // MARK: - Pagination State for Files
    private var currentFilesPage = 1
    var canLoadMoreFiles = true

    // MARK: - Properties for Creating PRs
    var newPRTitle: String = ""
    var newPRBody: String = ""
    var newPRBaseBranch: String? = nil
    var newPRHeadBranch: String? = nil
    var availableBranches: [GitHubBranchs] = []
    var isLoadingBranches: Bool = false
    var isCreatingPR: Bool = false
    var prCreationError: String? = nil
    var currentBranchNameFromGitService: String? = nil

    // MARK: - Properties for Merging PRs
    var mergeMethod: String = "merge"
    var mergeCommitTitle: String = ""
    var mergeCommitMessage: String = ""
    var isMerging: Bool = false
    var wasMergeSuccessful: Bool = false

    var reviewerStates: [ReviewerStateSummary] {
        var latestStates: [String: ReviewerStateSummary] = [:]

        // Sort reviews by submission time to process them chronologically
        let sortedReviews = reviews.sorted { ($0.submittedAt ?? .distantPast) < ($1.submittedAt ?? .distantPast) }

        for review in sortedReviews {
            // Ignore pending reviews
            guard review.state.uppercased() != "PENDING" else { continue }

            let summary = ReviewerStateSummary(
                user: PullRequestAuthor(id: review.user.id, login: review.user.login, avatarUrl: review.user.avatarUrl, htmlUrl: review.user.htmlUrl),
                state: ReviewerStateSummary.State(from: review.state)
            )
            latestStates[review.user.login] = summary
        }

        return Array(latestStates.values).sorted { $0.user.login < $1.user.login }
    }

    // MARK: - Dependencies
    private let gitProviderService: GitProviderService
    private let account: Account
    let repository: GitHubRepository

    init(gitProviderService: GitProviderService, account: Account, repository: GitHubRepository) {
        self.gitProviderService = gitProviderService
        self.account = account
        self.repository = repository
        self.newPRBaseBranch = repository.defaultBranch
    }

    // MARK: - Data Loading Methods for PR List
    @MainActor
    func loadPullRequests(refresh: Bool = false) async {
        if refresh {
            currentPRListPage = 1
            pullRequests = []
            canLoadMorePullRequests = true
            pullRequestListError = nil
        }

        guard canLoadMorePullRequests, !isLoadingPullRequests else { return }

        isLoadingPullRequests = true
        // if currentPRListPage == 1 { pullRequestListError = nil } // Clear error only on first page load/refresh

        do {
            let fetchedPRs = try await gitProviderService.fetchPullRequests(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                account: account,
                state: currentFilterState,
                page: currentPRListPage,
                perPage: pullRequestsPerPage
            )

            if fetchedPRs.isEmpty {
                canLoadMorePullRequests = false
            } else {
                pullRequests.append(contentsOf: fetchedPRs)
                currentPRListPage += 1
            }
        } catch let error as GitProviderServiceError {
            pullRequestListError = error.localizedDescription
            canLoadMorePullRequests = false
        } catch {
            pullRequestListError = "An unexpected error occurred: \(error.localizedDescription)"
            canLoadMorePullRequests = false
        }
        isLoadingPullRequests = false
    }

    // MARK: - Data Loading Methods for PR Details (Comments, Review Comments, Files)

    @MainActor
    func loadComments(refresh: Bool = false) async {
        guard let selectedPR = selectedPullRequest else { return }

        if refresh {
            currentCommentsPage = 1
            comments = []
            canLoadMoreComments = true
            commentsError = nil
        }

        guard canLoadMoreComments, !isLoadingMoreComments else { return }
        // isLoadingInitialDetails is managed by selectPullRequest
        isLoadingMoreComments = true
        // if currentCommentsPage == 1 { commentsError = nil } // Error is reset on refresh

        do {
            let fetchedComments = try await gitProviderService.fetchPullRequestComments(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account,
                page: currentCommentsPage,
                perPage: commentsPerPage
            )

            if fetchedComments.isEmpty {
                canLoadMoreComments = false
            } else {
                comments.append(contentsOf: fetchedComments)
                currentCommentsPage += 1
            }
        } catch let error as GitProviderServiceError {
            commentsError = "Error loading comments: \(error.localizedDescription)"
            canLoadMoreComments = false
        } catch {
            commentsError = "An unexpected error occurred while loading comments: \(error.localizedDescription)"
            canLoadMoreComments = false
        }
        isLoadingMoreComments = false
    }

    @MainActor
    func loadReviewComments(refresh: Bool = false) async {
        guard let selectedPR = selectedPullRequest else { return }

        if refresh {
            currentReviewCommentsPage = 1
            reviewComments = []
            canLoadMoreReviewComments = true
            reviewCommentsError = nil
            lineCommentsByFile = [:] // Reset the new dictionary
        }

        // This function will now fetch ALL review comments for the PR to build the lookup dictionary.
        // The old pagination logic is removed in favor of a comprehensive fetch.
        guard !isLoadingMoreReviewComments else { return }
        isLoadingMoreReviewComments = true
        defer { isLoadingMoreReviewComments = false }

        var allComments: [PullRequestComment] = []
        var page = 1
        let perPage = 100 // Fetch max per page

        do {
            while true {
                let fetchedComments = try await gitProviderService.fetchPullRequestReviewComments(
                    owner: repository.owner?.login ?? "",
                    repoName: repository.name,
                    prNumber: selectedPR.number,
                    account: account,
                    page: page,
                    perPage: perPage
                )

                allComments.append(contentsOf: fetchedComments)

                if fetchedComments.count < perPage {
                    break // Last page reached
                }
                page += 1
            }

            // Group comments by file path
            self.lineCommentsByFile = Dictionary(grouping: allComments.filter { $0.path != nil }, by: { $0.path! })

        } catch let error as GitProviderServiceError {
            reviewCommentsError = "Error loading review comments: \(error.localizedDescription)"
        } catch {
            reviewCommentsError = "An unexpected error occurred while loading review comments: \(error.localizedDescription)"
        }
    }

    @MainActor
    func loadFiles(refresh: Bool = false) async {
         guard let selectedPR = selectedPullRequest else { return }

        if refresh {
            currentFilesPage = 1
            files = []
            canLoadMoreFiles = true
            filesError = nil
        }

        guard canLoadMoreFiles, !isLoadingMoreFiles else { return }
        isLoadingMoreFiles = true

        do {
            let fetchedFiles = try await gitProviderService.fetchPullRequestFiles(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account,
                page: currentFilesPage,
                perPage: filesPerPage
            )

            if fetchedFiles.isEmpty {
                canLoadMoreFiles = false
            } else {
                files.append(contentsOf: fetchedFiles)
                currentFilesPage += 1
            }
        } catch let error as GitProviderServiceError {
            filesError = "Error loading files: \(error.localizedDescription)"
            canLoadMoreFiles = false
        } catch {
            filesError = "An unexpected error occurred while loading files: \(error.localizedDescription)"
            canLoadMoreFiles = false
        }
        isLoadingMoreFiles = false
    }

    @MainActor
    func loadReviews(refresh: Bool = false) async {
        guard let selectedPR = selectedPullRequest else { return }

        // For reviews, we usually load all of them, but pagination is possible.
        // Here, we'll just load the first page for simplicity unless refresh is true.
        if refresh {
            reviews = []
            reviewsError = nil
        }

        // Avoid re-loading if we already have reviews, unless refreshing.
        guard reviews.isEmpty || refresh else { return }

        isLoadingReviews = true
        defer { isLoadingReviews = false }

        do {
            let fetchedReviews = try await gitProviderService.fetchPullRequestReviews(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account
            )
            reviews = fetchedReviews
        } catch let error as GitProviderServiceError {
            reviewsError = "Error loading reviews: \(error.localizedDescription)"
        } catch {
            reviewsError = "An unexpected error occurred while loading reviews: \(error.localizedDescription)"
        }
    }

    // MARK: - Selection and Filtering
    @MainActor
    func selectPullRequest(_ pr: PullRequest) async {
        // Always clear state before loading new PR
        selectedPullRequest = pr
        comments = []
        reviewComments = []
        files = []
        reviews = []
        lineCommentsByFile = [:]
        commentsError = nil
        reviewCommentsError = nil
        filesError = nil
        reviewsError = nil
        isLoadingInitialDetails = true

        // Use a TaskGroup to load details concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadComments(refresh: true) }
            group.addTask { await self.loadReviewComments(refresh: true) }
            group.addTask { await self.loadFiles(refresh: true) }
            group.addTask { await self.loadReviews(refresh: true) }
        }
        isLoadingInitialDetails = false
    }

    @MainActor
    func clearSelection() {
        selectedPullRequest = nil
        pullRequestListError = nil

        comments = []
        reviewComments = []
        files = []
        reviews = []
        lineCommentsByFile = [:]

        commentsError = nil
        reviewCommentsError = nil
        filesError = nil
        reviewsError = nil

        currentCommentsPage = 1
        canLoadMoreComments = true
        currentReviewCommentsPage = 1
        canLoadMoreReviewComments = true
        currentFilesPage = 1
        canLoadMoreFiles = true
    }

    // MARK: - Data Loading and Actions for Creating PRs (Implementation mostly unchanged)
    @MainActor
    func fetchBranchesForCurrentRepository() async {
        isLoadingBranches = true
        prCreationError = nil
        do {
            availableBranches = try await gitProviderService.fetchBranches(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                account: account
            )
            if newPRHeadBranch == nil, let currentLocalBranch = currentBranchNameFromGitService, availableBranches.contains(where: { $0.name == currentLocalBranch }) {
                 newPRHeadBranch = currentLocalBranch
            } else if newPRHeadBranch == nil, let firstNonBaseBranch = availableBranches.first(where: { $0.name != newPRBaseBranch}) {
                 newPRHeadBranch = firstNonBaseBranch.name
            }
            if newPRBaseBranch == nil, let defaultBranch = repository.defaultBranch, availableBranches.contains(where: { $0.name == defaultBranch }) {
                newPRBaseBranch = defaultBranch
            }

        } catch let error as GitProviderServiceError {
            prCreationError = "Failed to load branches: \(error.localizedDescription)"
            availableBranches = []
        } catch {
            prCreationError = "An unexpected error occurred while loading branches: \(error.localizedDescription)"
            availableBranches = []
        }
        isLoadingBranches = false
    }

    @MainActor
    func createPullRequest() async {
        guard let base = newPRBaseBranch, let head = newPRHeadBranch, !newPRTitle.isEmpty else {
            prCreationError = "Title, base branch, and head branch are required."
            return
        }
        guard base != head else {
            prCreationError = "Base and head branches cannot be the same."
            return
        }
        isCreatingPR = true
        prCreationError = nil
        do {
            let newPR = try await gitProviderService.createPullRequest(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                account: account,
                title: newPRTitle,
                body: newPRBody,
                head: head,
                base: base
            )
            isCreatingPR = false
            pullRequests.insert(newPR, at: 0)
            newPRTitle = ""
            newPRBody = ""
            // Consider refreshing the PR list to get the absolute latest state from server
            // await loadPullRequests(refresh: true)
        } catch let error as GitProviderServiceError {
            prCreationError = "Failed to create pull request: \(error.localizedDescription)"
        } catch {
            prCreationError = "An unexpected error occurred while creating the pull request: \(error.localizedDescription)"
        }
        isCreatingPR = false
    }

    // MARK: - PR Actions

    @MainActor
    func prepareMergeDetails() {
        guard let pr = selectedPullRequest else { return }
        mergeCommitTitle = pr.title
        mergeCommitMessage = pr.body ?? ""
        mergeError = nil
        wasMergeSuccessful = false // Reset on preparing for a new merge
    }

    @MainActor
    func mergePullRequest() async {
        guard let pr = selectedPullRequest else {
            mergeError = "No pull request selected."
            return
        }

        isMerging = true
        mergeError = nil
        defer { isMerging = false }

        do {
            try await gitProviderService.mergePullRequest(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: pr.number,
                account: account,
                commitTitle: mergeCommitTitle,
                commitMessage: mergeCommitMessage,
                mergeMethod: mergeMethod
            )
            // After successful merge, refresh the PR state
            await self.loadPullRequests(refresh: true)
            wasMergeSuccessful = true
        } catch let error as GitProviderServiceError {
            mergeError = error.localizedDescription
        } catch {
            mergeError = "An unexpected error occurred during merge: \(error.localizedDescription)"
        }
    }

    @MainActor
    func approvePullRequest() async {
        await submitReview(event: .approve, body: "Approved")
    }

    @MainActor
    func requestChanges(comment: String) async {
        await submitReview(event: .requestChanges, body: comment)
    }

    @MainActor
    func addLineComment(body: String, commitId: String, path: String, line: Int) async {
        guard let pr = selectedPullRequest else { return }

        // This is a simplified approach. A full implementation might involve creating a pending review,
        // adding comments to it, and then submitting the review.
        // For now, we post a standalone comment.
        do {
            try await gitProviderService.addLineCommentToPullRequest(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: pr.number,
                account: account,
                body: body,
                commitId: commitId,
                path: path,
                line: line
            )
            // Refresh code comments after adding one
            await loadReviewComments(refresh: true)
        } catch {
            // Handle error, e.g., show an alert to the user
            print("Failed to add line comment: \(error.localizedDescription)")
        }
    }

    private func submitReview(event: GitProviderService.PullRequestReviewEvent, body: String?) async {
        guard let pr = selectedPullRequest else { return }

        // You might want to handle loading/error states for this action
        do {
            try await gitProviderService.submitPullRequestReview(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: pr.number,
                account: account,
                event: event,
                body: body
            )
            // Refresh reviews and PR details
            await self.loadReviews(refresh: true)
        } catch {
            // Handle error, e.g., show an alert
            print("Failed to submit review: \(error.localizedDescription)")
        }
    }
}

struct ReviewerStateSummary: Identifiable {
    var id: String { user.login }
    let user: PullRequestAuthor
    let state: State

    enum State: String {
        case approved = "Approved"
        case changesRequested = "Changes Requested"
        case commented = "Commented"
        case unknown = "Unknown"

        init(from string: String) {
            switch string.uppercased() {
            case "APPROVED": self = .approved
            case "CHANGES_REQUESTED": self = .changesRequested
            case "COMMENTED": self = .commented
            default: self = .unknown
            }
        }
    }
}

