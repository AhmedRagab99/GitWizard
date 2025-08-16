import Foundation

class GitHubOrganization: Identifiable, Codable, Hashable {
    static func == (lhs: GitHubOrganization, rhs: GitHubOrganization) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
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
