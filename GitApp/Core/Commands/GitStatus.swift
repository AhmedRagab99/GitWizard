//
//  GitStatus.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

final class GitStatus: Git {
    internal init(directory: URL) {
        self.directory = directory
    }

    typealias OutputModel = Status
    var arguments: [String] {
        [
            "git",
            "status",
            "--porcelain",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> Status {
        let lines = stdOut.components(separatedBy: .newlines)
        var status = Status()

        for line in lines {
            if line.isEmpty { continue }

            let statusCode = String(line.prefix(2))
            let filePath = line.count > 3 ? String(line.dropFirst(3)) : ""

            if statusCode == "??" {
                status.untrackedFiles.append(filePath)
            } else if statusCode == "UU" || statusCode == "AA" || statusCode == "DD" {
                // UU: both modified (conflict)
                // AA: both added (conflict)
                // DD: both deleted (conflict)
                status.conflicted.append(filePath)
            } else if statusCode.contains("U") || statusCode.contains("A") && statusCode.contains("D") {
                // Other conflict scenarios:
                // AU: added by us, modified by them
                // UA: modified by us, added by them
                // DU: deleted by us, modified by them
                // UD: modified by us, deleted by them
                status.conflicted.append(filePath)
            }
        }

        return status
    }
}
