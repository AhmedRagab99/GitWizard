import Foundation

struct GitBranchCreate: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "branch",
            name
        ]
    }
    var directory: URL
    let name: String

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
