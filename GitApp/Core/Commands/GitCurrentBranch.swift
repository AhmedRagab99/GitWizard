import Foundation

final class GitCurrentBranch: Git {
    internal init(directory: URL) {
        self.directory = directory
    }
    
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
