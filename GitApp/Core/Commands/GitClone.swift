import Foundation

struct GitClone: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "clone",
            repositoryURL,
            destinationPath
        ]
    }
    var directory: URL
    let repositoryURL: String
    let destinationPath: String

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
