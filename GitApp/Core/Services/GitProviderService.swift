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
    private let githubAPIBaseURL = "https://api.github.com"

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
        guard account.provider.lowercased() == "github" else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        var urlComponents = URLComponents(string: "\(githubAPIBaseURL)/repos/\(owner)/\(repoName)/pulls")

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
        guard account.type.rawValue.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.type.rawValue)
        }

        let urlString = "\(githubAPIBaseURL)/repos/\(owner)/\(repoName)/pulls/\(prNumber)"
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
        guard account.provider.lowercased().contains("github") else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }


        // Using issue comments endpoint: /repos/{owner}/{repo}/issues/{issue_number}/comments
        var urlComponents = URLComponents(string: "\(githubAPIBaseURL)/repos/\(owner)/\(repoName)/issues/\(prNumber)/comments")
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

    /// Fetches files changed in a given pull request from GitHub.
    func fetchPullRequestFiles(
        owner: String,
        repoName: String,
        prNumber: Int,
        account: Account,
        page: Int = 1,
        perPage: Int = 100 // Max per_page for files is often 100 for GitHub
    ) async throws -> [PullRequestFile] {
        guard account.provider.lowercased() == "github" else {
            throw GitProviderServiceError.unsupportedProvider(account.provider)
        }

        // Endpoint: /repos/{owner}/{repo}/pulls/{pull_number}/files
        var urlComponents = URLComponents(string: "\(githubAPIBaseURL)/repos/\(owner)/\(repoName)/pulls/\(prNumber)/files")
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
}
