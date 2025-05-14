import Foundation

final class GitUnstageAll: Git {
    internal init(directory: URL) {
        self.directory = directory
    }
    
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "reset",
            "."
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
