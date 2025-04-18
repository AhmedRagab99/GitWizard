import Foundation

struct Branch: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isCurrent: Bool
    let isRemote: Bool
    let lastCommit: String
    let lastCommitMessage: String
    let lastCommitDate: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.id == rhs.id
    }
}
