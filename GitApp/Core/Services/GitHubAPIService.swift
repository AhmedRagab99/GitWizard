import Foundation
import SwiftUI

class GitHubAPIService {
    // No direct baseURL or authToken storage here anymore

    init() {
        // Initialization logic if needed, but token will be passed per request
    }

    // MARK: - Pull Requests

    /// Fetch pull requests for a GitHub repository
    /// - Parameters:
    ///   - apiEndpoint: Base URL of the GitHub API
    ///   - owner: Repository owner (username or organization)
    ///   - repo: Repository name
    ///   - token: Authentication token
    ///   - state: PR state filter (open, closed, all)
    ///   - sort: Sort field (created, updated, popularity, long-running)
    ///   - direction: Sort direction (asc, desc)
    func fetchPullRequests(apiEndpoint: URL, owner: String, repo: String, token: String, state: String = "all", sort: String = "updated", direction: String = "desc") async throws -> [PullRequest] {
        var components = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)!
        components.path += "/repos/\(owner)/\(repo)/pulls" // Append to existing path from apiEndpoint
        components.path = components.path.replacingOccurrences(of: "//", with: "/")

        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "direction", value: direction),
            URLQueryItem(name: "per_page", value: "100")
        ]

        guard let url = components.url else {
            throw GitHubAPIError.invalidURL
        }

        let data = try await performRequest(url: url, token: token)
        return try parsePullRequests(from: data)
    }

    /// Fetch a specific pull request by number
    /// - Parameters:
    ///   - apiEndpoint: Base URL of the GitHub API
    ///   - owner: Repository owner (username or organization)
    ///   - repo: Repository name
    ///   - number: Pull request number
    ///   - token: Authentication token
    func fetchPullRequest(apiEndpoint: URL, owner: String, repo: String, number: Int, token: String) async throws -> PullRequest {
        var components = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)!
        components.path += "/repos/\(owner)/\(repo)/pulls/\(number)"
        components.path = components.path.replacingOccurrences(of: "//", with: "/")

        guard let url = components.url else {
            throw GitHubAPIError.invalidURL
        }

        let prDataResponse = try await performRequest(url: url, token: token)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let prDecodedData: PullRequestResponse
        do {
            prDecodedData = try decoder.decode(PullRequestResponse.self, from: prDataResponse)
        } catch {
            print("Error decoding PR data: \(error.localizedDescription)")
            throw GitHubAPIError.invalidResponse
        }

        // Get PR files in parallel
        var filesComponents = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)!
        filesComponents.path += "/repos/\(owner)/\(repo)/pulls/\(number)/files"
        filesComponents.path = filesComponents.path.replacingOccurrences(of: "//", with: "/")

        var files: [PullRequestFileResponse] = []
        var comments: [PullRequestCommentResponse] = []

        if let filesUrl = filesComponents.url {
            do {
                let filesData = try await performRequest(url: filesUrl, token: token)
                files = try decoder.decode([PullRequestFileResponse].self, from: filesData)
            } catch {
                print("Failed to load PR files: \(error.localizedDescription)")
            }
        }

        // Get PR comments in parallel
        var commentsComponents = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: true)!
        commentsComponents.path += "/repos/\(owner)/\(repo)/pulls/\(number)/comments"
        commentsComponents.path = commentsComponents.path.replacingOccurrences(of: "//", with: "/")

        if let commentsUrl = commentsComponents.url {
            do {
                let commentsData = try await performRequest(url: commentsUrl, token: token)
                comments = try decoder.decode([PullRequestCommentResponse].self, from: commentsData)
            } catch {
                print("Failed to load PR comments: \(error.localizedDescription)")
            }
        }

        return convertToPullRequest(prDecodedData, files: files, comments: comments)
    }

    /// Extract repository owner and name from remote URL
    /// - Parameter url: Git remote URL (e.g. https://github.com/owner/repo.git)
    /// - Returns: Tuple containing owner and repo name
    func extractOwnerAndRepo(from url: String) -> (owner: String, repo: String)? {
        // Handle different URL formats

        // Format: https://github.com/owner/repo.git or git@github.com:owner/repo.git
        // More robust regex to handle both https and ssh, and various GitHub Enterprise URLs
        // This regex assumes a structure like `domain/owner/repo` or `domain:owner/repo`
        let patterns = [
            "github\\.com[/:]([^/]+)/([^/\\\\.]+)(\\\\.git)?$", // Standard GitHub HTTPS/SSH
            "([^/]+)/([^/]+)/([^/\\\\.]+)(\\\\.git)?$", // Potential GHE: host/owner/repo.git (less specific)
            "git@([^:]+):([^/]+)/([^/\\\\.]+)(\\\\.git)?$" // Standard SSH format
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = url as NSString
                if let match = regex.firstMatch(in: url, range: NSRange(location: 0, length: nsString.length)) {
                    var ownerIndex = 1
                    var repoIndex = 2

                    if pattern.contains("git@") { // SSH format
                        ownerIndex = 2
                        repoIndex = 3
                    } else if pattern.contains("([^/]+)/([^/]+)/([^/\\\\.]+)") && !url.contains("github.com"){ // GHE-like host/owner/repo
                         // This is a bit tricky. If the first part is a host, we need to ensure it's not confused.
                         // For now, let's assume the second group is owner and third is repo.
                         // This part might need more robust handling based on actual GHE URL structures.
                         // A simpler way might be to parse the URL and take the last two path components.

                        // Let's try parsing as URL first for GHE
                        if let parsedURL = URL(string: url) {
                            let pathComponents = parsedURL.pathComponents.filter { $0 != "/" }
                            if pathComponents.count >= 2 {
                                let potentialRepo = pathComponents.last!
                                let potentialOwner = pathComponents[pathComponents.count - 2]
                                return (potentialOwner, potentialRepo.replacingOccurrences(of: ".git", with: ""))
                            }
                        }
                        // If URL parsing didn't work well for GHE, fall back to regex indices,
                        // but this regex pattern is very general.
                        ownerIndex = 2 // Assuming second group is owner for the host/owner/repo pattern
                        repoIndex = 3 // Assuming third group is repo
                    }

                    let owner = nsString.substring(with: match.range(at: ownerIndex))
                    var repo = nsString.substring(with: match.range(at: repoIndex))

                    if repo.hasSuffix(".git") {
                        repo = String(repo.dropLast(4))
                    }
                    return (owner, repo)
                }
            }
        }
        print("Could not extract owner/repo from URL: \(url)")
        return nil
    }

    // MARK: - Helper Methods

    private func performRequest(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Or be flexible if other methods are needed

        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // Potentially add other headers like "X-GitHub-Api-Version" if needed

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("GitHub API Error (Status \(httpResponse.statusCode)) for URL \(url.absoluteString): \(responseBody)")
            throw GitHubAPIError.requestFailed(statusCode: httpResponse.statusCode, message: responseBody)
        }

        return data
    }

    // MARK: - Parsing Methods

    private func parsePullRequests(from data: Data) throws -> [PullRequest] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let responses = try decoder.decode([PullRequestResponse].self, from: data)

        return responses.map { prResponse in
            // Create basic PR objects from list response
            PullRequest(
                id: String(prResponse.id),
                number: prResponse.number,
                title: prResponse.title,
                description: prResponse.body ?? "",
                author: prResponse.user.login,
                state: convertPRState(prResponse.state, merged: prResponse.mergedAt != nil),
                createdAt: prResponse.createdAt,
                updatedAt: prResponse.updatedAt,
                baseBranch: prResponse.base.ref,
                headBranch: prResponse.head.ref,
                files: [], // Will be loaded separately when viewing PR details
                comments: [], // Will be loaded separately when viewing PR details
                reviewStatus: .pending // Default status, will be updated when viewing PR details
            )
        }
    }

    private func convertToPullRequest(_ response: PullRequestResponse, files: [PullRequestFileResponse], comments: [PullRequestCommentResponse]) -> PullRequest {
        // Convert files
        let prFiles = files.map { fileResponse -> PullRequestFile in
            // Determine file status first
            let status = convertFileStatus(fileResponse.status)

            // Check if this is a binary file
            let isBinary = isBinaryFile(
                fileResponse.filename,
                additions: fileResponse.additions,
                deletions: fileResponse.deletions,
                changes: fileResponse.changes,
                patch: fileResponse.patch
            )

            // Initialize FileDiff based on file status and patch availability
            var fileDiff: FileDiff

            if isBinary {
                fileDiff = FileDiff(binary: fileResponse.filename)
            } else if let patch = fileResponse.patch, !patch.isEmpty {
                do {
                    // Create a properly formatted diff for the FileDiff parser
                    // Add header information if it's not already present
                    var processedPatch = patch

                    // If patch doesn't start with diff header, add one
                    if !processedPatch.hasPrefix("diff --git") {
                        let header = "diff --git a/\(fileResponse.filename) b/\(fileResponse.filename)\n"
                        let indexLine = "index 0000000..0000000 100644\n"
                        let fromFile = "--- a/\(fileResponse.filename)\n"
                        let toFile = "+++ b/\(fileResponse.filename)\n"

                        // Only add what's missing
                        if !processedPatch.contains("--- a/") {
                            processedPatch = header + indexLine + fromFile + toFile + processedPatch
                        }
                    }

                    // Now parse with the properly formatted patch
                    fileDiff = try FileDiff(raw: processedPatch)
                } catch {
                    print("Error parsing patch for \(fileResponse.filename): \(error.localizedDescription)")
                    // Use appropriate fallback based on the file status
                    fileDiff = createFileDiffFallback(status: status, filename: fileResponse.filename)
                }
            } else {
                // No patch data available - use appropriate fallback
                fileDiff = createFileDiffFallback(status: status, filename: fileResponse.filename)
            }

            return PullRequestFile(
                path: fileResponse.filename,
                status: status,
                additions: fileResponse.additions,
                deletions: fileResponse.deletions,
                changes: fileResponse.changes,
                diff: fileDiff
            )
        }

        // Convert comments
        let prComments = comments.map { comment in
            PullRequestComment(
                id: String(comment.id),
                author: comment.user.login,
                content: comment.body,
                createdAt: comment.createdAt,
                path: comment.path,
                line: comment.line
            )
        }

        // Determine review status (simplified)
        let reviewStatus: ReviewStatus = response.state == "open" ? .pending :
                                         (response.mergedAt != nil ? .approved : .changesRequested)

        return PullRequest(
            id: String(response.id),
            number: response.number,
            title: response.title,
            description: response.body ?? "",
            author: response.user.login,
            state: convertPRState(response.state, merged: response.mergedAt != nil),
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            baseBranch: response.base.ref,
            headBranch: response.head.ref,
            files: prFiles,
            comments: prComments,
            reviewStatus: reviewStatus
        )
    }

    private func convertPRState(_ state: String, merged: Bool) -> PullRequestState {
        if merged {
            return .merged
        } else if state == "open" {
            return .open
        } else {
            return .closed
        }
    }

    private func convertFileStatus(_ status: String) -> FileStatus {
        let result: FileStatus

        switch status.lowercased() {
        case "added":
            result = .added
        case "modified":
            result = .modified
        case "removed", "deleted":
            result = .removed
        case "renamed":
            result = .renamed
        case "copied":
            result = .copied
        case "changed":
            result = .modified
        case "unchanged":
            result = .unknown
        default:
            print("Unknown GitHub file status: \(status), defaulting to modified")
            result = .modified
        }

        print("GitHub status '\(status)' converted to FileStatus.\(result)")
        return result
    }

    private func isBinaryFile(_ filename: String, additions: Int, deletions: Int, changes: Int, patch: String?) -> Bool {
        // Common binary file extensions
        let binaryExtensions = [
            ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".webp",  // Images
            ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", // Documents
            ".zip", ".tar", ".gz", ".7z", ".rar",                      // Archives
            ".exe", ".dll", ".so", ".dylib",                           // Executables and libraries
            ".mp3", ".mp4", ".wav", ".avi", ".mov",                    // Media
            ".ttf", ".otf", ".woff", ".woff2"                          // Fonts
        ]

        // Check extension
        if binaryExtensions.contains(where: filename.lowercased().hasSuffix) {
            return true
        }

        // Check file stats - if there are changes but no additions or deletions, likely binary
        if patch == nil && changes > 0 && additions == 0 && deletions == 0 {
            return true
        }

        return false
    }

    private func createFileDiffFallback(status: FileStatus, filename: String) -> FileDiff {
        switch status {
        case .added:
            return FileDiff(added: filename)
        case .removed, .deleted:
            return FileDiff(removed: filename)
        case .renamed:
            // For renamed files, we create a simple diff with the rename information
            let header = "diff --git a/\(filename) b/\(filename)"
            let extendedHeader = "rename from \(filename.split(separator: " => ").first ?? "")\nrename to \(filename.split(separator: " => ").last ?? "")"
            return FileDiff(
                raw: "\(header)\n\(extendedHeader)",
                header: header,
                extendedHeaderLines: [extendedHeader],
                fromFileToFileLines: [],
                chunks: []
            )
        case .modified:
            // For modified files with no patch, create a placeholder diff
            let header = "diff --git a/\(filename) b/\(filename)"
            let fromFile = "--- a/\(filename)"
            let toFile = "+++ b/\(filename)"
            return FileDiff(
                raw: "\(header)\n\(fromFile)\n\(toFile)",
                header: header,
                extendedHeaderLines: [],
                fromFileToFileLines: [fromFile, toFile],
                chunks: []
            )
        case .copied:
            // Similar to renamed, but with copy information
            let header = "diff --git a/\(filename) b/\(filename)"
            let extendedHeader = "copy from \(filename)\ncopy to \(filename)"
            return FileDiff(
                raw: "\(header)\n\(extendedHeader)",
                header: header,
                extendedHeaderLines: [extendedHeader],
                fromFileToFileLines: [],
                chunks: []
            )
        default:
            // For other statuses like binary files, create a generic diff
            if isBinaryFile(filename, additions: 0, deletions: 0, changes: 0, patch: nil) {
                return FileDiff(binary: filename)
            } else {
                // Default case
                return FileDiff(untrackedFile: filename)
            }
        }
    }
}

// MARK: - API Response Models

struct PullRequestResponse: Codable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let state: String
    let createdAt: Date
    let updatedAt: Date
    let mergedAt: Date?
    let user: GitHubUser
    let head: GitHubRef
    let base: GitHubRef

    enum CodingKeys: String, CodingKey {
        case id, number, title, body, state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case mergedAt = "merged_at"
        case user, head, base
    }
}

struct GitHubRef: Codable {
    let label: String
    let ref: String
    let sha: String
}

struct PullRequestFileResponse: Codable {
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let changes: Int
    let patch: String?
}

struct PullRequestCommentResponse: Codable {
    let id: Int
    let user: GitHubUser
    let body: String
    let createdAt: Date
    let path: String?
    let line: Int?

    enum CodingKeys: String, CodingKey {
        case id, user, body
        case createdAt = "created_at"
        case path, line
    }
}

// MARK: - Errors

enum GitHubAPIError: Error {
    case requestFailed(statusCode: Int, message: String)
    case invalidURL
    case invalidResponse
    case unauthorized
}
