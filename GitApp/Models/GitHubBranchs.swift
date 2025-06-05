import Foundation

// Model for a GitHub Branch, named GitHubBranchs as per user's decode line
struct GitHubBranchs: Codable, Identifiable, Hashable {
    let name: String
    let commit: GitHubBranchCommit
    let protected: Bool? // Protected status might not always be present or relevant

    // Conform to Identifiable using the branch name
    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case commit
        case protected
    }
}

// Nested struct for the commit information within a branch
struct GitHubBranchCommit: Codable, Hashable {
    let sha: String
    // let url: String? // Optional if you need the commit URL
}
