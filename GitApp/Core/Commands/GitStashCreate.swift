import Foundation

struct GitStashCreate: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "stash",
            "push",
            "-m",
            message
        ]
    }
    var directory: URL
    let message: String

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
