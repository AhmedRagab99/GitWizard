import Foundation


struct Branch: Hashable, Identifiable {
    let detachedPrefix = "(HEAD detached at "

    var id: String {
        name
    }
    var isRemote: Bool {
        // Check if branch name starts with "origin/" which indicates a remote branch
        return name.hasPrefix("origin/")
    }
    var name: String
    var isCurrent: Bool
    var point: String {
        if isDetached {
            return String(name.dropFirst(detachedPrefix.count).dropLast(1))
        }
        return name
    }
    var isDetached: Bool {
        return name.hasPrefix(detachedPrefix)
    }

    var displayName: String {
        if isRemote {
            return name.replacingOccurrences(of: "origin/", with: "")
        }
        return name
    }

    var remoteName: String {
        if isRemote {
            return name.replacingOccurrences(of: "origin/", with: "")
        }
        return name
    }
}

extension [Branch] {
    var current: Branch? {
        first { $0.isCurrent }
    }
}

//struct Branch: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let isCurrent: Bool
//    let isRemote: Bool
//    let upstream: String?
//    let lastCommitDate: Date?
//    let lastCommitMessage: String?
//
//    var displayName: String {
//        if isRemote {
//            return name.replacingOccurrences(of: "origin/", with: "")
//        }
//        return name
//    }
//
//    var isHead: Bool {
//        return name == "HEAD" || name.hasSuffix("/HEAD")
//    }
//
//    static func == (lhs: Branch, rhs: Branch) -> Bool {
//        return lhs.name == rhs.name && lhs.isCurrent == rhs.isCurrent
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(name)
//        hasher.combine(isCurrent)
//    }
//}
