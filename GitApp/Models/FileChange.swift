import Foundation

struct FileChange: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var status: String // e.g., "Modified", "Added", "Deleted"
}
