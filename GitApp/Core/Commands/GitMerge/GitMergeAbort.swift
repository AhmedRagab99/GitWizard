import Foundation

struct GitMergeAbort: Git {
    typealias OutputModel = Void

    var directory: URL

    var command: String {
        "git"
    }

    var arguments: [String] {
        ["git", "merge", "--abort"]
    }

    func parse(for output: String) throws -> OutputModel {

    }
}
