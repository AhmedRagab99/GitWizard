import Foundation

class GitHubUser: Identifiable, Codable, Hashable {
    
    static func == (lhs: GitHubUser, rhs: GitHubUser) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
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
    
    init(id: Int, login: String, avatarUrl: String?, htmlUrl: String?, name: String? = nil, company: String? = nil, blog: String? = nil, location: String? = nil, email: String? = nil, bio: String? = nil, publicRepos: Int? = nil, followers: Int? = nil, following: Int? = nil) {
        self.id = id
        self.login = login
        self.avatarUrl = avatarUrl
        self.htmlUrl = htmlUrl
        self.name = name
        self.company = company
        self.blog = blog
        self.location = location
        self.email = email
        self.bio = bio
        self.publicRepos = publicRepos
        self.followers = followers
        self.following = following
    }

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
