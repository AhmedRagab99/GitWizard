import Foundation

struct GitDiff: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
            "git",
            "diff",
        ]
        if noRenames {
            args.append("--no-renames")
        }
        if cached {
            args.append("--cached")
        }
        if !commitsRange.isEmpty {
            args.append(commitsRange)
        }
        return args
    }
    var directory: URL
    var noRenames = true
    var cached = false
    var commitsRange = ""

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
