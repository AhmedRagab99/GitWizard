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

            // Handle renamed files and their paths separately, e.g., "R  old -> new"
            if statusCode.starts(with: "R") {
                // This case can be enhanced if rename status needs to be tracked
                continue
            }

            // Robustly parse the file path, handling potential quotes
            let pathComponent = String(line.dropFirst(3))
            let filePath = pathComponent.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            // Correctly identify all conflict/unmerged statuses
            let isConflict = statusCode.contains("U") || statusCode == "AA" || statusCode == "DD"

            if statusCode == "??" {
                status.untrackedFiles.append(filePath)
            } else if isConflict {
                status.conflicted.append(filePath)
            }
        }

        return status
    }
}
