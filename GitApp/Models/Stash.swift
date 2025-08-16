import Foundation

class Stash: Identifiable, Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
    static func == (lhs: Stash, rhs: Stash) -> Bool {
        lhs.index == rhs.index
    }
    
    var id: Int { index }
    var index: Int
    var message: String
    var raw: String

    init(index: Int, raw: String) {
        self.index = index
        self.raw = raw
        self.message = String(raw.split(separator: ":", maxSplits: 1).map { String($0) }[safe: 1]?.dropFirst() ?? "")
    }
}
