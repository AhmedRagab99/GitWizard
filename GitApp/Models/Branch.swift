import Foundation

struct Branch: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isCurrent: Bool = false
}
