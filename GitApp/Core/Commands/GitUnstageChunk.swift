import Foundation

struct GitUnstageChunk: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "reset",
            "-p",
            filePath
        ]
    }
    var directory: URL
    let filePath: String
    let chunk: Chunk

    func parse(for stdOut: String) throws -> String {
        return stdOut
    }
}
