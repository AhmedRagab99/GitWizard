import Foundation

struct Tag: Identifiable, Hashable {
    let id: UUID
    let name: String
    let commitHash: String
    let message: String
    let date: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}
