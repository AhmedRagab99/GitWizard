import Foundation

struct GitHubOrganization: Identifiable, Codable, Hashable {
    let id: Int
    let login: String
    let avatarUrl: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case description
    }
}
