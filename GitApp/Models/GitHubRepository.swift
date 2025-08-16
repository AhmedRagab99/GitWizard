import Foundation

struct GitHubRepository: Identifiable, Codable, Hashable, Equatable {
    static func == (lhs: GitHubRepository, rhs: GitHubRepository) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let name: String
    let fullName: String
    let owner: GitHubUser? // Can be a user or an organization; simplify to User for now
    let htmlUrl: String
    let description: String?
    let sshUrl: String? // For SSH cloning
    let cloneUrl: String? // For HTTPS cloning
    let stargazersCount: Int?
    let watchersCount: Int?
    let language: String?
    let forksCount: Int?
    let openIssuesCount: Int?
    let license: GitHubLicense?
    let isPrivate: Bool
    let defaultBranch: String?
    

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case htmlUrl = "html_url"
        case description
        case sshUrl = "ssh_url"
        case cloneUrl = "clone_url"
        case stargazersCount = "stargazers_count"
        case watchersCount = "watchers_count"
        case language
        case forksCount = "forks_count"
        case openIssuesCount = "open_issues_count"
        case license
        case isPrivate = "private"
        case defaultBranch = "default_branch"
    }
}

struct GitHubLicense: Identifiable, Codable, Hashable, Equatable {
    var id: String { key } // Use key as a unique identifier if available
    let key: String
    let name: String
    let spdxId: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case key
        case name
        case spdxId = "spdx_id"
        case url
    }
}
