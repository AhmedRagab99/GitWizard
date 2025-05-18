import Foundation

final class GitRemoteList: Git {
    typealias OutputModel = String

    var arguments: [String] = [
        "git",
        "remote"
    ]

    var directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    func parse(for stdOut: String) -> String {
        return stdOut
    }
}
