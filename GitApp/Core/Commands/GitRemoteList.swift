import Foundation

struct GitRemoteList: Git {
    typealias OutputModel = [String]
    var arguments: [String] {
        [
            "git",
            "remote"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> [String] {
        return stdOut.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
