import Foundation
import SwiftUI

/// Represents a pull request from a Git provider.
struct PullRequest: Codable, Identifiable, Hashable {
    let id: Int // Unique ID from the provider (e.g., GitHub PR ID)
    let number: Int // PR number within the repository
    let title: String
    let user: PullRequestAuthor // The author of the PR
    var state: String // e.g., "open", "closed". We can map this to PullRequestState enum later.
    let body: String? // The description of the PR (markdown)
    let createdAt: Date
    let updatedAt: Date
    let closedAt: Date?
    let mergedAt: Date?

    let htmlUrl: String // URL to view the PR on the web
    let diffUrl: String // URL to get the diff of the PR
    let patchUrl: String // URL to get the patch of the PR
    let commentsUrl: String // URL to fetch comments for the PR
    let head: GitReference
    let base: GitReference

    // Additional potentially useful fields (depending on provider)
    // let assignee: PullRequestAuthor?
    // let assignees: [PullRequestAuthor]?
    // let labels: [Label]?

    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case user
        case state
        case body
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
        case mergedAt = "merged_at"
        case htmlUrl = "html_url"
        case diffUrl = "diff_url"
        case patchUrl = "patch_url"
        case commentsUrl = "comments_url"
        case head, base
        // case reviewCommentsUrl = "review_comments_url"
        // case commitsUrl = "commits_url"
        // case labels
    }

    // Helper to map string state to PullRequestState enum
    var prState: PullRequestState {
        if mergedAt != nil {
            return .merged
        }
        switch state.lowercased() {
        case "open":
            return .open
        case "closed":
            return .closed
        default:
            return .closed // Default or handle as unknown
        }
    }

     var prStatusColor: Color {
        switch prState {
        case .open:
            return .green
        case .closed:
            return .red
        case .merged:
            return .purple
        case .all:
            return .gray
        }
    }

     var prStatusIconName: String {
        switch prState {
        case .open:
            return "arrow.triangle.pull"
        case .closed:
            return "xmark.circle.fill"
        case .merged:
            return "arrow.triangle.merge"
        case .all: // Should not happen for a specific PR state
            return "questionmark.circle"
        }
    }
}

struct GitReference: Codable, Hashable {
    let label: String // e.g., "octocat:new-feature"
    let ref: String // branch name, e.g., "new-feature"
    let sha: String // commit SHA
}

/*
// Example GitReference and Label structs if needed later
struct GitReference: Codable, Hashable {
    let ref: String // branch name, e.g., "new-feature"
    let sha: String // commit SHA
    // let user: PullRequestAuthor? // User/Org that owns the repo
    // let repo: RepositoryInfo? // Basic repo info
}

struct Label: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let color: String // Hex color string
    let description: String?
}
*/
