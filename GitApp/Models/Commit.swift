import Foundation
import SwiftUI

struct Commit: Identifiable, Hashable {
    
    let id = UUID()
    let hash: String
    let shortHash: String
    let author: String
    let message: String
    let date: Date
    var branches: [String] = []
    var isSelected: Bool = false
    var isCurrent: Bool = false
    var parentHashes: [String] = []
    var isMergeCommit: Bool {
        return parentHashes.count > 1
    }

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
    var tags: [String]
    var commitType: CommitType = .normal

    enum CommitType: String, Hashable {
        case normal
        case merge
        case rebase
        case cherryPick
        case revert

        var  commitIcon:  (name: String, color: Color) {
            switch self {
            case .merge:
                return ("arrow.triangle.merge", .blue)
            case .rebase:
                return ("arrow.triangle.branch", .purple)
            case .cherryPick:
                return ("arrow.triangle.pull", .pink)
            case .revert:
                return ("arrow.uturn.backward", .red)
            case .normal:
                return ("checkmark.circle.fill", .green)
            }
        }
    }
}


