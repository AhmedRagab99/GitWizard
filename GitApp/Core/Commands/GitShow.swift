//
//  GitShow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

//%H|%an|%ae|%ad|%s|%P
struct GitShow: Git {
    typealias OutputModel = CommitDetails
    var arguments: [String] {
        [
            "git",
            "show",
            "--pretty=format:%H"
            + .formatSeparator + "%P"
            + .formatSeparator + "%an"
            + .formatSeparator + "%aE"
            + .formatSeparator + "%aI"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> CommitDetails {
        guard !stdOut.isEmpty else { throw GenericError(errorDescription: "Parse error: stdOut is empty.") }
        let splits = stdOut.split(separator: String.componentSeparator + "\n", maxSplits: 1)
        let commitInfo = splits[0]
        let separated = commitInfo.components(separatedBy: String.formatSeparator)
        let refs: [String]
        if separated[7].isEmpty {
            refs = []
        } else {
            refs = separated[7].components(separatedBy: ", ")
        }

        let hash = separated[0]
        let shortHash = String(hash.prefix(7))
        let title = separated[5]

        // Parse date from ISO format
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: separated[4]) ?? Date()

        let commit = Commit(
            hash: hash,
            shortHash: shortHash,
            author: separated[2],
            message: title,
            date: date,
            branches: refs.filter { !$0.hasPrefix("tag: ") },
            parentHashes: separated[1].components(separatedBy: .whitespacesAndNewlines),
            authorEmail: separated[3],
            authorDate: separated[4],
            authorAvatar: URL.gravater(email: separated[3])?.absoluteString ?? "",
            title: separated[5],
            body: separated[6],
            tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
        )
        return CommitDetails(
            commit: commit,
            diff: try Diff(raw: String(splits[safe: 1] ?? ""))
        )
    }
}

