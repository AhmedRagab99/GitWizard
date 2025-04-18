import Foundation

struct WorkspaceCommand: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String // SF Symbol name
}
