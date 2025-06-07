import Foundation

// Enum to represent possible errors from the GitProviderService
enum GitProviderServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case apiError(statusCode: Int, message: String?)
    case decodingError(Error)
    case noAccessToken
    case unsupportedProvider(String)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL for the API request was invalid."
        case .networkError(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API Error (Status \(statusCode)): \(message ?? "Unknown error")"
        case .decodingError(let underlyingError):
            return "Failed to decode the response: \(underlyingError.localizedDescription)"
        case .noAccessToken:
            return "No access token available for the account."
        case .unsupportedProvider(let provider):
            return "The Git provider '\(provider)' is not currently supported for this operation."
        case .malformedResponse:
            return "The response from the server was malformed."
        }
    }
}

class GitProviderService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601 // Common for GitHub API dates
        // self.decoder.keyDecodingStrategy = .convertFromSnakeCase // Already handled by CodingKeys in models
    }

    // MARK: - GitHub API Constants
    // private let githubAPIBaseURL = "https://api.github.com" // No longer needed as a class constant

    // MARK: - Pull Request Fetching

    /// Fetches pull requests for a given repository from GitHub.
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - repoName: The name of the repository.
    ///   - account: The account to use for authentication.
    ///   - state: The state of pull requests to fetch (e.g., open, closed, all).
    ///   - page: The page number for pagination.
    ///   - perPage: The number of items per page.
    /// - Returns: An array of `PullRequest` objects.
    /// - Throws: `GitProviderServiceError` if an error occurs.
    func fetchPullRequests(
        owner: String,
        repoName: String,
        account: Account,
        state: PullRequestState = .open, // Using our enum, will map to string for API
        page: Int = 1,
        perPage: Int = 30
    ) async throws -> [PullRequest] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL // Or a more specific error if account.apiEndpoint is nil
        }

        // The provider check can remain as is, or be more specific if needed.
        // e.g., guard account.type == .githubCom || account.type == .githubEnterprise else { ... }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/pulls")

        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        // Map PullRequestState to GitHub API state parameter
        let apiState: String
        switch state {
        case .open:
            apiState = "open"
        case .closed, .merged: // GitHub API uses 'closed' for both. Merged status is checked via 'merged_at'.
            apiState = "closed"
        case .all:
            apiState = "all"
        }
        queryItems.append(URLQueryItem(name: "state", value: apiState))

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version") // Optional: Pin API version

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                // Try to decode error message from GitHub if any
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            let pullRequests = try decoder.decode([PullRequest].self, from: data)
            return pullRequests
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    /// Fetches details for a single pull request from GitHub.
    func fetchPullRequestDetails(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account
    ) async throws -> PullRequest {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.type.rawValue.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.type.rawValue)
        }

        let urlString = "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)"
        guard let url = URL(string: urlString) else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            let pullRequestDetails = try decoder.decode(PullRequest.self, from: data)
            return pullRequestDetails
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    /// Fetches comments for a given pull request from GitHub.
    /// PRs are issues, so we use the issues comments endpoint for general discussion.
    /// For review comments on code, use `pulls/{pull_number}/comments`. This fetches general comments.
    func fetchPullRequestComments(
        owner: String,
        repoName: String,
        prNumber: Int, // This is the PR number, which also serves as the issue number
        account: Account,
        page: Int = 1,
        perPage: Int = 30
    ) async throws -> [PullRequestComment] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }


        // Using issue comments endpoint: /repos/{owner}/{repo}/issues/{issue_number}/comments
        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/issues/\(prNumber)/comments")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        let request = try createAuthenticatedRequest(url: url, account: account, httpMethod: "GET")

        do {
            let (data, response) = try await session.data(for: request)
            try self.validateResponse(response: response, data: data)
            let comments = try decoder.decode([PullRequestComment].self, from: data)
            return comments
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    /// Fetches review comments (comments on code lines) for a given pull request from GitHub.
    func fetchPullRequestReviewComments(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        page: Int = 1,
        perPage: Int = 100 // Review comments can be numerous; 100 is often max per page
    ) async throws -> [PullRequestComment] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        // Endpoint: /repos/{owner}/{repo}/pulls/{pull_number}/comments
        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/comments")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            // Assuming PullRequestComment model is suitable for review comments too.
            // GitHub API for PR review comments returns an array of comment objects.
            let reviewComments = try decoder.decode([PullRequestComment].self, from: data)
            return reviewComments
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    /// Fetches files changed in a given pull request from GitHub.
    func fetchPullRequestFiles(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        page: Int = 1,
        perPage: Int = 100 // Max per_page for files is often 100 for GitHub
    ) async throws -> [PullRequestFile] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        // Endpoint: /repos/{owner}/{repo}/pulls/{pull_number}/files
        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/files")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            let files = try decoder.decode([PullRequestFile].self, from: data)
            return files
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    // MARK: - Branch Fetching

    /// Fetches branches for a given repository from GitHub.
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - repoName: The name of the repository.
    ///   - account: The account to use for authentication.
    ///   - page: The page number for pagination.
    ///   - perPage: The number of items per page (max 100).
    /// - Returns: An array of `GitHubBranchs` objects.
    /// - Throws: `GitProviderServiceError` if an error occurs.
    func fetchBranches(
        owner: String,
        repoName: String,
        account: Account,
        page: Int = 1,
        perPage: Int = 100 // Max 100 per page for branches
    ) async throws -> [GitHubBranchs] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        // Assuming GitHub-like provider
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/branches")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            // Assuming your Branch model matches the GitHub API response for branches
            let branches = try decoder.decode([GitHubBranchs].self, from: data)
            return branches
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    // MARK: - Pull Request Creation

    /// Creates a new pull request on GitHub.
    /// - Parameters:
    ///   - owner: The owner of the repository.
    ///   - repoName: The name of the repository.
    ///   - account: The account to use for authentication.
    ///   - title: The title of the pull request.
    ///   - body: The description/body of the pull request.
    ///   - head: The name of the branch where your changes are implemented.
    ///   - base: The name of the branch you want the changes pulled into.
    /// - Returns: The created `PullRequest` object.
    /// - Throws: `GitProviderServiceError` if an error occurs.
    func createPullRequest(
        owner: String,
        repoName: String,
        account: Account,
        title: String,
        body: String,
        head: String, // e.g., "feature-branch"
        base: String  // e.g., "main"
    ) async throws -> PullRequest {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        let urlString = "\(baseURLString)/repos/\(owner)/\(repoName)/pulls"
        guard let url = URL(string: urlString) else {
            throw GitProviderServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "title": title,
            "body": body,
            "head": head,
            "base": base
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            throw GitProviderServiceError.networkError(error) // Or a more specific parameter encoding error
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitProviderServiceError.malformedResponse
            }
            // GitHub returns 201 Created on success
            guard (200..<300).contains(httpResponse.statusCode) else { // 201 is typical for successful POST
                let errorMessage = String(data: data, encoding: .utf8)
                // Attempt to parse GitHub's error message structure if possible
                // For now, just passing the raw string.
                throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            let createdPR = try decoder.decode(PullRequest.self, from: data)
            return createdPR
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    // MARK: - Pull Request Actions

    func mergePullRequest(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        commitTitle: String,
        commitMessage: String?,
        mergeMethod: String
    ) async throws {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        let urlString = "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/merge"
        guard let url = URL(string: urlString) else {
            throw GitProviderServiceError.invalidURL
        }

        var request = try createAuthenticatedRequest(url: url, account: account, httpMethod: "PUT")

        let body: [String: Any?] = [
            "commit_title": commitTitle,
            "commit_message": commitMessage,
            "merge_method": mergeMethod // "merge", "squash", or "rebase"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        do {
            let (data, response) = try await session.data(for: request)
            try self.validateResponse(response: response, data: data, expectedStatusCode: 200)
        } catch {
            // More specific error handling could be added here based on the response body
            // For example, if merging is not allowed.
            throw error
        }
    }

    enum PullRequestReviewEvent: String {
        case approve = "APPROVE"
        case requestChanges = "REQUEST_CHANGES"
        case comment = "COMMENT"
    }

    func submitPullRequestReview(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        event: PullRequestReviewEvent,
        body: String?
    ) async throws {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        let urlString = "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/reviews"
        guard let url = URL(string: urlString) else {
            throw GitProviderServiceError.invalidURL
        }

        var request = try createAuthenticatedRequest(url: url, account: account, httpMethod: "POST")

        let bodyDict: [String: Any?] = [
            "event": event.rawValue,
            "body": body
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict.compactMapValues { $0 })

        do {
            let (data, response) = try await session.data(for: request)
            try self.validateResponse(response: response, data: data)
        } catch {
            throw error
        }
    }

    func fetchPullRequestReviews(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        page: Int = 1,
        perPage: Int = 100
    ) async throws -> [PullRequestReview] {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        var urlComponents = URLComponents(string: "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/reviews")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents?.url else {
            throw GitProviderServiceError.invalidURL
        }

        let request = try createAuthenticatedRequest(url: url, account: account, httpMethod: "GET")

        do {
            let (data, response) = try await session.data(for: request)
            try self.validateResponse(response: response, data: data)
            let reviews = try decoder.decode([PullRequestReview].self, from: data)
            return reviews
        } catch let error as GitProviderServiceError {
            throw error
        } catch let decodingError as DecodingError {
            throw GitProviderServiceError.decodingError(decodingError)
        } catch {
            throw GitProviderServiceError.networkError(error)
        }
    }

    func addLineCommentToPullRequest(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        body: String,
        commitId: String,
        path: String,
        line: Int
    ) async throws {
        guard let baseURLString = account.apiEndpoint?.absoluteString else {
            throw GitProviderServiceError.invalidURL
        }
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        let urlString = "\(baseURLString)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/comments"
        guard let url = URL(string: urlString) else {
            throw GitProviderServiceError.invalidURL
        }

        var request = try createAuthenticatedRequest(url: url, account: account, httpMethod: "POST")

        let bodyDict: [String: Any] = [
            "body": body,
            "commit_id": commitId,
            "path": path,
            "line": line
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)

        do {
            let (data, response) = try await session.data(for: request)
            try self.validateResponse(response: response, data: data)
        } catch {
            throw error
        }
    }

    // MARK: - Branch Management

    /// Fetches branches for a given repository from the Git provider.
    private func createAuthenticatedRequest(url: URL, account: Account, httpMethod: String = "GET") throws -> URLRequest {
        var request = URLRequest(url: url)
        guard !account.token.isEmpty else {
            throw GitProviderServiceError.noAccessToken
        }
        request.setValue("Bearer \(account.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.httpMethod = httpMethod
        if httpMethod == "POST" || httpMethod == "PUT" || httpMethod == "PATCH" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func validateResponse(response: URLResponse, data: Data, expectedStatusCode: Int = -1) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitProviderServiceError.malformedResponse
        }

        let successRange = (200..<300)
        let isValidStatus = (expectedStatusCode != -1) ? (httpResponse.statusCode == expectedStatusCode) : successRange.contains(httpResponse.statusCode)

        guard isValidStatus else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw GitProviderServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
}
