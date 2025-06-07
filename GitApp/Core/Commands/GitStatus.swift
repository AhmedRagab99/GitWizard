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
        var status = Status()
        let lines = stdOut.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for line in lines {
            let index = line.index(line.startIndex, offsetBy: 2)
            let statusCode = String(line[..<index])
            // Drop the space after the status code
            let path = String(line[line.index(index, offsetBy: 1)...])

            // Unquote paths, which can happen with files containing spaces
            let finalPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            let xy = statusCode.map { String($0) }
            let x = xy[0]
            let y = xy[1]

            // For untracked files
            if x == "?" && y == "?" {
                status.untrackedFiles.append(finalPath)
                continue
            }

            // For conflicted files.
            // DD: Unmerged, both deleted
            // AU: Unmerged, added by us
            // UD: Unmerged, file deleted by them
            // UA: Unmerged, file added by them
            // DU: Unmerged, file deleted by us
            // AA: Unmerged, both added
            // UU: Unmerged, both modified
            if (x == "D" && y == "D") || (x == "A" && y == "A") || x == "U" || y == "U" {
                status.conflicted.append(finalPath)
            }
        }

        return status
    }
}
