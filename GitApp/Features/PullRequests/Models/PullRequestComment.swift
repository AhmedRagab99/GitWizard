import Foundation

/// Represents a comment on a pull request.
struct PullRequestComment: Codable, Identifiable, Hashable {
    let id: Int // Unique ID of the comment
    let user: PullRequestAuthor // The author of the comment
    let body: String // The content of the comment (markdown)
    let createdAt: Date
    let updatedAt: Date
    let htmlUrl: String? // URL to view the comment on the web

    enum CodingKeys: String, CodingKey {
        case id
        case user
        case body
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case htmlUrl = "html_url"
    }
}
