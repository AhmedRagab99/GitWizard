import Foundation

@Observable
class PullRequestViewModel  {
    // MARK: - Properties
    var pullRequests: [PullRequest] = []
    var comments: [PullRequestComment] = []
    var files: [PullRequestFile] = []
    var selectedPullRequest: PullRequest? {
        didSet {
            if selectedPullRequest != nil {
                // Task to load details is now in selectPullRequest method
            }
        }
    }
    var isLoadingPullRequests = false
    var isLoadingDetails = false // For comments/files of a selected PR
    var errorMessage: String?
    var currentFilterState: PullRequestState = .open {
        didSet {
            // Re-fetch PRs when filter changes
            Task {
                await loadPullRequests(refresh: true) // Refresh when filter changes
            }
        }
    }

    // MARK: - Dependencies
    private let gitProviderService: GitProviderService
    private let account: Account
    private let repository: GitHubRepository // Contains owner login and repo name

    // MARK: - Pagination State (Example for PR list)
    private var currentPage = 1
    private let itemsPerPage = 20
    var canLoadMorePullRequests = true

    init(gitProviderService: GitProviderService, account: Account, repository: GitHubRepository) {
        self.gitProviderService = gitProviderService
        self.account = account
        self.repository = repository
    }

    // MARK: - Data Loading Methods
    @MainActor
    func loadPullRequests(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            pullRequests = []
            canLoadMorePullRequests = true
        }

        guard canLoadMorePullRequests, !isLoadingPullRequests else { return }

        isLoadingPullRequests = true
        errorMessage = nil

        do {
            let fetchedPRs = try await gitProviderService.fetchPullRequests(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                account: account,
                state: currentFilterState,
                page: currentPage,
                perPage: itemsPerPage
            )

            if fetchedPRs.isEmpty {
                canLoadMorePullRequests = false
            } else {
                pullRequests.append(contentsOf: fetchedPRs)
                currentPage += 1
            }
        } catch let error as GitProviderServiceError {
            errorMessage = error.localizedDescription
            canLoadMorePullRequests = false // Stop pagination on error
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            canLoadMorePullRequests = false // Stop pagination on error
        }
        isLoadingPullRequests = false
    }

    @MainActor
    func loadCommentsForSelectedPullRequest() async {
        guard let selectedPR = selectedPullRequest else { return }

        isLoadingDetails = true
        // errorMessage = nil // Don't clear general error message here, could be from PR list load
        comments = [] // Clear previous comments

        do {
            let fetchedComments = try await gitProviderService.fetchPullRequestComments(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account,
                page: 1, // Add pagination for comments if needed
                perPage: 100 // Fetch up to 100 comments for now
            )
            comments = fetchedComments
        } catch let error as GitProviderServiceError {
            errorMessage = "Error loading comments: \(error.localizedDescription)"
        } catch {
            errorMessage = "An unexpected error occurred while loading comments: \(error.localizedDescription)"
        }
        isLoadingDetails = false
    }

    @MainActor
    func loadFilesForSelectedPullRequest() async {
        guard let selectedPR = selectedPullRequest else { return }

        isLoadingDetails = true
        // errorMessage = nil // Don't clear general error message here
        files = [] // Clear previous files

        do {
            let fetchedFiles = try await gitProviderService.fetchPullRequestFiles(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                prNumber: selectedPR.number,
                account: account,
                page: 1, // Add pagination for files if needed
                perPage: 100 // GitHub API typically limits files per page
            )
            files = fetchedFiles
        } catch let error as GitProviderServiceError {
            errorMessage = "Error loading files: \(error.localizedDescription)"
        } catch {
            errorMessage = "An unexpected error occurred while loading files: \(error.localizedDescription)"
        }
        isLoadingDetails = false
    }

    // MARK: - Selection and Filtering
    @MainActor
    func selectPullRequest(_ pr: PullRequest) {
        selectedPullRequest = pr
        // Automatically load details when a PR is selected
        Task {
            // Clear previous details first
            self.comments = []
            self.files = []
            // Load new details
            await loadCommentsForSelectedPullRequest()
            await loadFilesForSelectedPullRequest()
        }
    }

    @MainActor
    func clearSelection() {
        selectedPullRequest = nil
        comments = []
        files = []
    }
}
