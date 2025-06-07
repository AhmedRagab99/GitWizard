import Foundation

final class GitResetHard: Git {
    typealias OutputModel = Void

    var directory: URL
    var arguments: [String] = ["git", "reset", "--hard"]

    init(directory: URL) {
        self.directory = directory
    }

    func parse(for output: String) throws -> Void {

    }
}
