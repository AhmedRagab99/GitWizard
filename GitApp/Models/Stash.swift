import Foundation

struct Stash: Identifiable, Hashable {
    let id = UUID()
    var description: String
    var date: Date
}
