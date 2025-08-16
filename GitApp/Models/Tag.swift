import Foundation

class Tag: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let commitHash: String
    let message: String
    let date: Date

    
    init(name: String, commitHash: String, message: String, date: Date) {
        self.name = name
        self.commitHash = commitHash
        self.message = message
        self.date = date
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}
