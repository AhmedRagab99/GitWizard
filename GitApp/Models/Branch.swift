import Foundation

struct Branch: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isCurrent: Bool
    let isRemote: Bool
    let upstream: String?
    let lastCommitDate: Date?
    let lastCommitMessage: String?

    var displayName: String {
        if isRemote {
            return name.replacingOccurrences(of: "origin/", with: "")
        }
        return name
    }

    var isHead: Bool {
        return name == "HEAD" || name.hasSuffix("/HEAD")
    }

    static func == (lhs: Branch, rhs: Branch) -> Bool {
        return lhs.name == rhs.name && lhs.isCurrent == rhs.isCurrent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isCurrent)
    }
}
