import Foundation

struct GitResetChunk: InteractiveGit {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
            "git",
            "checkout",
            "-p"
        ]

        if !filePath.isEmpty {
            args.append("--")
            args.append(filePath)
        }

        return args
    }
    var directory: URL
    var inputs: [String]
    let filePath: String

    init(directory: URL, filePath: String, inputs: [String]) {
        self.directory = directory
        self.filePath = filePath
        self.inputs = inputs
    }

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
