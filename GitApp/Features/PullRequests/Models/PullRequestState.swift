import Foundation

/// Represents the state of a pull request.
enum PullRequestState: String, Codable, CaseIterable, Identifiable {
    case open
    case closed
    case merged // GitHub uses 'closed' for merged PRs but often has a 'merged_at' field. Some APIs might have 'merged'.
    case all // For filtering purposes

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .open:
            return "Open"
        case .closed:
            return "Closed"
        case .merged:
            return "Merged"
        case .all:
            return "All"
        }
    }
}
