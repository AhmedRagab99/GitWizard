import Foundation

struct GitBlame: Git {
    typealias OutputModel = [BlameLine]

    let directory: URL
    let filePath: String

    var arguments: [String] {
        ["git", "blame", "--line-porcelain", filePath]
    }

    func parse(for output: String) throws -> [BlameLine] {
        var blameLines = [BlameLine]()
        let lines = output.components(separatedBy: .newlines)

        var currentAuthor = ""
        var currentCommitHash = ""
        var currentDate = Date()
        var lineNumber = 1

        for line in lines where !line.isEmpty {
            if line.hasPrefix("author ") {
                currentAuthor = String(line.dropFirst(7))
            } else if line.hasPrefix("committer-time ") {
                if let timestamp = TimeInterval(line.dropFirst(14)) {
                    currentDate = Date(timeIntervalSince1970: timestamp)
                }
            } else if line.hasPrefix("author-mail ") {
                // We could extract email if needed
            } else if line.hasPrefix("commit ") {
                currentCommitHash = String(line.dropFirst(7).prefix(7)) // Shortened hash
            } else if line.hasPrefix("\t") {
                // This is the actual code line
                let codeLine = String(line.dropFirst())
                let blameLine = BlameLine(
                    lineNumber: lineNumber,
                    author: currentAuthor,
                    commitHash: currentCommitHash,
                    date: currentDate,
                    content: codeLine
                )
                blameLines.append(blameLine)
                lineNumber += 1
            }
        }

        return blameLines
    }
}
