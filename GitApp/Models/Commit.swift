import Foundation

struct Commit: Hashable, Identifiable {
    var id: String { hash }
    var hash: String
    var parentHashes: [String]
    var author: String
    var authorEmail: String
    var authorDate: String
    var authorAvatar: String
    var authorDateDisplay: String {
        guard let date = ISO8601DateFormatter().date(from: authorDate) else {
            return ""
        }
        return DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .long)
    }
    var authorDateRelative: String {
        guard let date = ISO8601DateFormatter().date(from: authorDate) else {
            return ""
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    var title: String
    var body: String
    var rawBody: String {
        guard !body.isEmpty else {
            return title
        }
        return title + "\n\n" + body
    }
    var branches: [String]
    var tags: [String]
    var commitType: CommitType = .normal


    enum CommitType: String, Hashable {
        case normal
        case merge
        case rebase
        case cherryPick
        case revert
        }
}


// private functions
extension Commit {
    private func determineCommitType(message: String, parentHashes: [String]) -> Commit.CommitType {
        let lowercasedMessage = message.lowercased()

        if parentHashes.count > 1 {
            return .merge
        } else if lowercasedMessage.contains("rebase") {
            return .rebase
        } else if lowercasedMessage.contains("cherry-pick") {
            return .cherryPick
        } else if lowercasedMessage.contains("revert") {
            return .revert
        } else {
            return .normal
        }
    }
}
