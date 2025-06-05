import Foundation

@Observable
class PullRequestViewModel  {
    // MARK: - Properties for Listing/Viewing PRs
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

    // MARK: - Properties for Creating PRs
    var newPRTitle: String = ""
    var newPRBody: String = ""
    var newPRBaseBranch: String? = nil
    var newPRHeadBranch: String? = nil
    var availableBranches: [GitHubBranchs] = []
    var isLoadingBranches: Bool = false
    var isCreatingPR: Bool = false
    var prCreationError: String? = nil
    // Placeholder for current branch, ideally obtained from a local GitService
    var currentBranchNameFromGitService: String? = nil

    // MARK: - Dependencies
    private let gitProviderService: GitProviderService
    private let account: Account
    let repository: GitHubRepository // Made public for CreatePullRequestView to access defaultBranch

    // MARK: - Pagination State (Example for PR list)
    private var currentPage = 1
    private let itemsPerPage = 20
    var canLoadMorePullRequests = true

    init(gitProviderService: GitProviderService, account: Account, repository: GitHubRepository) {
        self.gitProviderService = gitProviderService
        self.account = account
        self.repository = repository
        // Attempt to set default base branch. Head branch might need more specific logic (e.g., current local branch).
        self.newPRBaseBranch = repository.defaultBranch
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

    // MARK: - Data Loading and Actions for Creating PRs
    @MainActor
    func fetchBranchesForCurrentRepository() async {
        isLoadingBranches = true
        prCreationError = nil // Clear previous creation errors when fetching branches
        do {
            availableBranches = try await gitProviderService.fetchBranches(
                owner: repository.owner?.login ?? "",
                repoName: repository.name,
                account: account
            )
            // Try to set a sensible default for head branch if not already set and different from base
            if newPRHeadBranch == nil, let currentLocalBranch = currentBranchNameFromGitService, availableBranches.contains(where: { $0.name == currentLocalBranch }) {
                 newPRHeadBranch = currentLocalBranch
            } else if newPRHeadBranch == nil, let firstNonBaseBranch = availableBranches.first(where: { $0.name != newPRBaseBranch}) {
                 newPRHeadBranch = firstNonBaseBranch.name
            }
            // Ensure base branch is set if it was nil and default is available
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
            // Success
            isCreatingPR = false
            // Add to the list of PRs (or refresh list)
            pullRequests.insert(newPR, at: 0) // Add to top for immediate visibility
            // Reset form
            newPRTitle = ""
            newPRBody = ""
            // newPRBaseBranch = repository.defaultBranch // Keep base branch as is or reset? User might want to create another PR against same base.
            // newPRHeadBranch = nil // Reset head branch or smart select next?

            // Optionally, reload all pull requests to ensure data consistency
            // await loadPullRequests(refresh: true)

        } catch let error as GitProviderServiceError {
            prCreationError = "Failed to create pull request: \(error.localizedDescription)"
        } catch {
            prCreationError = "An unexpected error occurred while creating the pull request: \(error.localizedDescription)"
        }
        isCreatingPR = false
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
