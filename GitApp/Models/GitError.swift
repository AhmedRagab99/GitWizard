import Foundation

enum GitError: LocalizedError {
    case repositoryNotFound
    case invalidRepository
    case commandFailed(String)
    case networkError(String)
    case authenticationError
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .repositoryNotFound:
            return "Repository not found"
        case .invalidRepository:
            return "Invalid repository"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationError:
            return "Authentication failed"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}
