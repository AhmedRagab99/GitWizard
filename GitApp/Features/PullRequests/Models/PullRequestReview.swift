import Foundation

struct PullRequestReview: Codable, Identifiable, Hashable {
    let id: Int
    let user: GitHubUser
    let body: String?
    let state: String // "APPROVED", "COMMENTED", "CHANGES_REQUESTED"
    let submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, user, body, state
        case submittedAt = "submitted_at"
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PullRequestReview, rhs: PullRequestReview) -> Bool {
        lhs.id == rhs.id
    }
}
