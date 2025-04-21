import Foundation

struct GitCurrentBranch: Git {
    typealias OutputModel = String?
    var arguments: [String] {
        [
            "git",
            "rev-parse",
            "--abbrev-ref",
            "HEAD"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> String? {
        let branch = stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
        return branch.isEmpty ? nil : branch
    }
}
