import Foundation

struct GitTagList: Git {
    typealias OutputModel = [Tag]
    var arguments: [String] {
        [
            "git",
            "tag",
            "-l",
            "--format=%(refname:short)|%(objectname)|%(contents:subject)|%(creatordate:iso8601)"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> [Tag] {
        return stdOut.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line in
                let components = line.components(separatedBy: "|")
                let name = components[0]
                let commitHash = components[1]
                let message = components[2]
                let date = ISO8601DateFormatter().date(from: components[3]) ?? Date()

                return Tag(
                    name: name,
                    commitHash: commitHash,
                    message: message,
                    date: date
                )
            }
    }
}
