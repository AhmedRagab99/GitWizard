import Foundation

struct FileChange: Identifiable, Hashable {
    let id: UUID
    let name: String
    let status: String
    let path: String
    var stagedChanges: [LineChange]
    var unstagedChanges: [LineChange]

    var lineChanges: [LineChange] {
        stagedChanges + unstagedChanges
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileChange, rhs: FileChange) -> Bool {
        lhs.id == rhs.id
    }
}

