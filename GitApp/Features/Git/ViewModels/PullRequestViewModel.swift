import Foundation
import Observation
import SwiftUI

@Observable
class PullRequestViewModel {
    // MARK: - Properties

    // Pull request data
    private(set) var pullRequests: [PullRequest] = []
    private(set) var selectedPullRequest: PullRequest?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // Filter options
    var filterState: PullRequestState? = .open
    var sortBy: PRSortOption = .updated
    var sortDirection: SortDirection = .descending
    var searchText: String = ""

    // API Service
    let githubService = GitHubAPIService()

    // Repository information
    private var repositoryOwner: String?
    private var repositoryName: String?

    // Computed properties
    var filteredPullRequests: [PullRequest] {
        var filtered = pullRequests

        // Filter by state if needed
        if let state = filterState {
            filtered = filtered.filter { $0.state == state }
        }

        // Filter by search text if provided
        if !searchText.isEmpty {
            filtered = filtered.filter { pr in
                pr.title.localizedCaseInsensitiveContains(searchText) ||
                pr.description.localizedCaseInsensitiveContains(searchText) ||
                pr.author.localizedCaseInsensitiveContains(searchText) ||
                "#\(pr.number)".contains(searchText)
            }
        }

        // Sort the results
        switch sortBy {
        case .created:
            filtered.sort {
                sortDirection == .ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
            }
        case .updated:
            filtered.sort {
                sortDirection == .ascending ? $0.updatedAt < $1.updatedAt : $0.updatedAt > $1.updatedAt
            }
        case .number:
            filtered.sort {
                sortDirection == .ascending ? $0.number < $1.number : $0.number > $1.number
            }
        }

        return filtered
    }

    var stateCounters: [PullRequestState: Int] {
        var counters: [PullRequestState: Int] = [.open: 0, .closed: 0, .merged: 0]

        for pr in pullRequests {
            counters[pr.state, default: 0] += 1
        }

        return counters
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Setup repository information from Git remote URL
    func setupRepository(remoteURL: String) {
        if let (owner, repo) = githubService.extractOwnerAndRepo(from: remoteURL) {
            self.repositoryOwner = owner
            self.repositoryName = repo
        } else {
            errorMessage = "Could not extract repository information from the remote URL: \(remoteURL)"
        }
    }

    /// Set GitHub authentication token
    func setAuthToken(_ token: String) {
        githubService.setAuthToken(token)
    }

    /// Load pull requests for the current repository
    func loadPullRequests() async {
        guard let owner = repositoryOwner, let repo = repositoryName else {
            errorMessage = "Repository information not available"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let state = filterState == nil ? "all" : filterState!.rawValue
            let sort = sortBy.rawValue
            let direction = sortDirection.rawValue

            pullRequests = try await githubService.fetchPullRequests(
                owner: owner,
                repo: repo,
                state: state,
                sort: sort,
                direction: direction
            )

            isLoading = false
        } catch {
            pullRequests = []
            isLoading = false
            errorMessage = "Error loading pull requests: \(error.localizedDescription)"
        }
    }

    /// Load details for a specific pull request
    func loadPullRequestDetails(for pullRequest: PullRequest) async {
        guard let owner = repositoryOwner, let repo = repositoryName else {
            errorMessage = "Repository information not available"
            return
        }

        isLoading = true
        errorMessage = nil

        // Set the initial pull request as selected so the UI shows something while loading
        if selectedPullRequest == nil || selectedPullRequest?.id != pullRequest.id {
            selectedPullRequest = pullRequest
        }

        do {
            // Fetch detailed PR data
            let detailedPR = try await githubService.fetchPullRequest(
                owner: owner,
                repo: repo,
                number: pullRequest.number
            )

            // Update the selected PR with detailed info
            selectedPullRequest = detailedPR

            // Also update the PR in the main list for consistency
            if let index = pullRequests.firstIndex(where: { $0.id == detailedPR.id }) {
                pullRequests[index] = detailedPR
            }

            isLoading = false
        } catch {
            // Keep the current PR data if loading fails
            isLoading = false
            errorMessage = "Error loading pull request details: \(error.localizedDescription)"
        }
    }

    /// Apply filter by state
    func applyStateFilter(_ state: PullRequestState?) {
        self.filterState = state
    }

    /// Apply sorting options
    func applySorting(by option: PRSortOption, direction: SortDirection) {
        self.sortBy = option
        self.sortDirection = direction

        Task {
            await loadPullRequests()
        }
    }

    /// Clear selected PR
    func clearSelectedPullRequest() {
        selectedPullRequest = nil
    }
}

// MARK: - Supporting Types

enum PRSortOption: String, CaseIterable, Identifiable {
    case created
    case updated
    case number = "comments"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .created: return "Created Date"
        case .updated: return "Last Updated"
        case .number: return "PR Number"
        }
    }
}

enum SortDirection: String, CaseIterable, Identifiable {
    case ascending = "asc"
    case descending = "desc"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }

    var icon: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}
