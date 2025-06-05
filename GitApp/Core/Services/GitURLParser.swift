import Foundation

struct GitURLParser {

    struct ParsedURL {
        let hostname: String
        let owner: String
        let repoName: String
    }

    enum ParseError: Error {
        case invalidURLFormat
        case missingHost
        case missingOwnerOrRepo
    }

    /// Parses a Git remote URL (SSH or HTTPS) into its components.
    /// - Parameter remoteURL: The Git remote URL string.
    /// - Returns: A `ParsedURL` struct containing hostname, owner, and repo name.
    /// - Throws: `ParseError` if the URL format is invalid or components are missing.
    static func parse(remoteURL: String) throws -> ParsedURL {
        // Attempt to parse as an SSH URL first (e.g., git@github.com:owner/repo.git)
        if remoteURL.contains("@") && remoteURL.contains(":") {
            let parts = remoteURL.components(separatedBy: ":")
            guard parts.count == 2,
                  let hostPart = parts.first?.components(separatedBy: "@").last,
                  !hostPart.isEmpty else {
                throw ParseError.invalidURLFormat
            }

            let pathPart = parts[1]
            let ownerAndRepo = pathPart.replacingOccurrences(of: ".git", with: "")
            let ownerAndRepoComponents = ownerAndRepo.components(separatedBy: "/")
            guard ownerAndRepoComponents.count >= 2 else { // Allow for multi-level group/owner paths
                throw ParseError.missingOwnerOrRepo
            }

            let repoName = ownerAndRepoComponents.last!
            let owner = ownerAndRepoComponents.dropLast().joined(separator: "/")


            guard !owner.isEmpty, !repoName.isEmpty else {
                throw ParseError.missingOwnerOrRepo
            }
            return ParsedURL(hostname: hostPart, owner: owner, repoName: repoName)
        }

        // Attempt to parse as an HTTPS URL
        guard let url = URL(string: remoteURL), let host = url.host else {
            throw ParseError.invalidURLFormat
        }

        // Remove leading slash and .git suffix
        var pathComponents = url.pathComponents.filter { $0 != "/" }
        if pathComponents.last?.hasSuffix(".git") == true, let lastComponent = pathComponents.last {
            pathComponents[pathComponents.count - 1] = String(lastComponent.dropLast(4))
        }

        guard pathComponents.count >= 2 else { // Allow for multi-level group/owner paths
            throw ParseError.missingOwnerOrRepo
        }

        let repoName = pathComponents.last!
        let owner = pathComponents.dropLast().joined(separator: "/")

        guard !owner.isEmpty, !repoName.isEmpty else {
             throw ParseError.missingOwnerOrRepo
        }

        return ParsedURL(hostname: host, owner: owner, repoName: repoName)
    }
}
