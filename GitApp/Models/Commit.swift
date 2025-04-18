import Foundation

struct Commit: Identifiable, Hashable {
    let id: UUID
    let hash: String
    let authorName: String
    let authorEmail: String
    let date: Date
    let message: String
    let parentHashes: [String]
    var branchNames: [String]
    let commitType: CommitType
    let authorAvatar: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Commit, rhs: Commit) -> Bool {
        lhs.id == rhs.id
    }

    enum CommitType: String, Hashable {
        case normal
        case merge
        case rebase
        case cherryPick
        case revert
    }
}
