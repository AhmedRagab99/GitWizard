import Foundation

struct GitResetChunk: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "checkout",
            "--",
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
