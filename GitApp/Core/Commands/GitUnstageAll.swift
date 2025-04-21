import Foundation

struct GitUnstageAll: Git {
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
