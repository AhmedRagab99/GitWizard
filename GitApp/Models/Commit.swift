import Foundation

struct Commit: Identifiable, Hashable {
    let id = UUID()
    var hash: String
    var message: String
    var author: String
    var authorEmail: String
    var authorAvatar: String // URL or system image name
    var date: Date
    var changedFiles: [FileChange] = []
    var parentHashes: [String] = []
    var branchNames: [String] = []
    var commitType: CommitType = .normal
    var diffContent: String? // Store actual diff content
}
