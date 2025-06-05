import Foundation

/// Represents the author of a pull request.
struct PullRequestAuthor: Codable, Identifiable, Hashable {
    let id: Int // Often the user ID from the provider
    let login: String // Username
    let avatarUrl: String? // URL for the author's avatar image
    let htmlUrl: String? // URL to the author's profile page

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
    }
}
