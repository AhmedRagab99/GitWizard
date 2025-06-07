import Foundation

struct GitBranchStatus: Git {
    typealias OutputModel = [String: (ahead: Int, behind: Int)]
    var directory: URL
    let command = "for-each-ref"
    let format = "%(refname:short) %(upstream:track)"
    let refs = "refs/heads"

    var arguments: [String] {
        ["git", command, "--format='\(format)'", refs]
    }

    func parse(for output: String) throws -> OutputModel {
        var statusDict: [String: (ahead: Int, behind: Int)] = [:]
        let lines = output.split(whereSeparator: \.isNewline)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "'"))

            guard !trimmedLine.isEmpty else { continue }

            let components = trimmedLine.split(separator: " ", maxSplits: 1).map { String($0) }
            let branchName = components[0]

            var ahead = 0
            var behind = 0

            if components.count > 1 {
                let trackInfo = components[1]
                let pattern = #"ahead (\d+)|behind (\d+)"#
                let regex = try! NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: trackInfo, range: NSRange(trackInfo.startIndex..., in: trackInfo))

                for match in matches {
                    if let aheadRange = Range(match.range(at: 1), in: trackInfo),
                       let count = Int(trackInfo[aheadRange]) {
                        ahead = count
                    }
                    if let behindRange = Range(match.range(at: 2), in: trackInfo),
                       let count = Int(trackInfo[behindRange]) {
                        behind = count
                    }
                }
            }
            statusDict[branchName] = (ahead: ahead, behind: behind)
        }
        return statusDict
    }
}
