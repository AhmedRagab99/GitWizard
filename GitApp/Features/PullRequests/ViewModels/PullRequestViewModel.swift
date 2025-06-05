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
    var reviewComments: [PullRequestComment] = []
    var files: [PullRequestFile] = []
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

    // MARK: - Error Messages
    var pullRequestListError: String?
    var commentsError: String?
    var reviewCommentsError: String?
    var filesError: String?

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
        }

        guard canLoadMoreReviewComments, !isLoadingMoreReviewComments else { return }
        isLoadingMoreReviewComments = true

        do {
            let fetchedReviewComments = try await gitProviderService.fetchPullRequestReviewComments(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account,
                page: currentReviewCommentsPage,
                perPage: reviewCommentsPerPage
            )

            if fetchedReviewComments.isEmpty {
                canLoadMoreReviewComments = false
            } else {
                reviewComments.append(contentsOf: fetchedReviewComments)
                currentReviewCommentsPage += 1
            }
        } catch let error as GitProviderServiceError {
            reviewCommentsError = "Error loading review comments: \(error.localizedDescription)"
            canLoadMoreReviewComments = false
        } catch {
            reviewCommentsError = "An unexpected error occurred while loading review comments: \(error.localizedDescription)"
            canLoadMoreReviewComments = false
        }
        isLoadingMoreReviewComments = false
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

    // MARK: - Selection and Filtering
    @MainActor
    func selectPullRequest(_ pr: PullRequest) async {
        selectedPullRequest = pr

        isLoadingInitialDetails = true // Indicate that the initial set of details is being loaded.

        // Load initial page for all details concurrently, ensuring pagination states are reset by refresh:true.
        // Error properties (commentsError, etc.) are also reset within these load methods when refresh is true.
        async let commentsTask: () = loadComments(refresh: true)
        async let reviewCommentsTask: () = loadReviewComments(refresh: true)
        async let filesTask: () = loadFiles(refresh: true)

        _ = await [commentsTask, reviewCommentsTask, filesTask]

        isLoadingInitialDetails = false // All initial detail loads are complete.
    }

    @MainActor
    func clearSelection() {
        selectedPullRequest = nil
        pullRequestListError = nil

        comments = []
        reviewComments = []
        files = []

        commentsError = nil
        reviewCommentsError = nil
        filesError = nil

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
}

