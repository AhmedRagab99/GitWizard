import Foundation

struct GitGrep: Git {
    typealias OutputModel = [FileSearchResult]

    let directory: URL
    let pattern: String

    var arguments: [String] {
        ["git", "grep", "-n", pattern]
    }

    func parse(for output: String) throws -> [FileSearchResult] {
        var results = [FileSearchResult]()
        let lines = output.components(separatedBy: .newlines)

        for line in lines where !line.isEmpty {
            if let colonIndex = line.firstIndex(of: ":") {
                let filePath = String(line.prefix(upTo: colonIndex))
                let rest = String(line.suffix(from: line.index(after: colonIndex)))

                if let secondColonIndex = rest.firstIndex(of: ":") {
                    let lineNumber = String(rest.prefix(upTo: secondColonIndex))
                    let matchContent = String(rest.suffix(from: rest.index(after: secondColonIndex)))

                    let result = FileSearchResult(
                        filePath: filePath,
                        matchContent: matchContent,
                        lineNumber: Int(lineNumber) ?? 0
                    )
                    results.append(result)
                }
            }
        }

        return results
    }
}
