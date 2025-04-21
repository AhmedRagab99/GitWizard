import Foundation

struct GitStageChunk: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "add",
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
