import Foundation

struct GitHubUser: Identifiable, Codable, Hashable {
    let id: Int
    let login: String // Username
    let avatarUrl: String?
    let htmlUrl: String? // Link to GitHub profile
    let name: String? // Full name
    let company: String?
    let blog: String?
    let location: String?
    let email: String?
    let bio: String?
    let publicRepos: Int?
    let followers: Int?
    let following: Int?

    // CodingKeys to map from snake_case (API) to camelCase (Swift)
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case name
        case company
        case blog
        case location
        case email
        case bio
        case publicRepos = "public_repos"
        case followers
        case following
    }
}
