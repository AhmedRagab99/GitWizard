//
//  GitLog.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitLog: Git {
    internal init(directory: URL, merges: Bool = false, noMerges: Bool = false, ancestryPath: Bool = false, reverse: Bool = false, number: Int = 50, revisionRange: String = "", grep: [String] = [], grepAllMatch: Bool = false, s: String = "", g: String = "", author: String = "", branch: String = "", skip: Int = 0) {
        self.directory = directory
        self.merges = merges
        self.noMerges = noMerges
        self.ancestryPath = ancestryPath
        self.reverse = reverse
        self.number = number
        self.revisionRange = revisionRange
        self.grep = grep
        self.grepAllMatch = grepAllMatch
        self.s = s
        self.g = g
        self.author = author
        self.branch = branch
        self.skip = skip
    }


    var directory: URL
    var merges = false
    var noMerges = false
    var ancestryPath = false
    var reverse = false
    var number = 50 // Default to 50 commits per page
    var revisionRange = ""
    var grep: [String] = []
    var grepAllMatch = false
    var s = ""
    var g = ""
    var author = ""
    var branch = ""
    var skip = 0 // Add skip parameter for pagination

     typealias OutputModel = [Commit]

     var arguments: [String] {
//         %H|%an|%ae|%ad|%s|%P

        var args: [String] = [
            "git",
            "log",
            "--pretty=format:%H"
            + .formatSeparator + "%P"
            // author name
            + .formatSeparator + "%an"
            //
            + .formatSeparator + "%aE"
            + .formatSeparator + "%aI"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
            "--skip=\(skip)", // Add skip parameter
            "-n\(number)" // Use -n instead of - for better compatibility
        ]
        if merges {
            args.append("--merges")
        }
        if noMerges {
            args.append("--no-merges")
        }
        if ancestryPath {
            args.append("--ancestry-path")
        }
        if reverse {
            args.append("--reverse")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        args.append(contentsOf: grep.map { "--grep=\($0)" })
        if grepAllMatch {
            args.append("--all-match")
        }
        if !s.isEmpty {
            args.append("-S")
            args.append(s)
            args.append("--pickaxe-regex")
        }
        if !g.isEmpty {
            args.append("-G")
            args.append(g)
        }
        if !author.isEmpty {
            args.append("--author=\(author)")
        }
        return args
    }


     func parse(for stdOut: String) throws -> [Commit] {
         guard !stdOut.isEmpty else { return [] }
         let logs = stdOut.components(separatedBy: String.componentSeparator + "\n")
         return logs.map { log in
             let separated = log.components(separatedBy: String.formatSeparator)
             let refs: [String]
             if separated[7].isEmpty {
                 refs = []
             } else {
                 refs = separated[7].components(separatedBy: ", ")
             }

             let hash = separated[0]
             let shortHash = String(hash.prefix(7))
             let parentHash = separated[1].components(separatedBy: .whitespacesAndNewlines)
             let author = separated[2]
             let authorEmail = separated[3]
             let authorDate = separated[4]
             let title = separated[5]
             let body = separated[6]
             let branches = refs.filter { !$0.hasPrefix("tag: ") }
             let tags = refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
             // Generate avatar URL based on email (using Gravatar)
             let emailHash = authorEmail.lowercased().md5Hash
             let authorAvatar = "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=40"

             // Parse date from ISO format
             let dateFormatter = ISO8601DateFormatter()
             let date = dateFormatter.date(from: authorDate) ?? Date()

             return Commit(
                hash: hash,
                shortHash: shortHash,
                author: author,
                message: title,
                date: date,
                branches: branches,
                parentHashes: parentHash,
                authorEmail: authorEmail,
                authorDate: authorDate,
                authorAvatar: authorAvatar,
                title: title,
                body: body,
                tags: tags,
                commitType: determineCommitType(message: body, parentHashes: parentHash)
             )
         }
     }


     private func determineCommitType(message: String, parentHashes: [String]) -> Commit.CommitType {
         let lowercasedMessage = message.lowercased()

         if parentHashes.count > 1 {
             return .merge
         } else if lowercasedMessage.contains("rebase") {
             return .rebase
         } else if lowercasedMessage.contains("cherry-pick") {
             return .cherryPick
         } else if lowercasedMessage.contains("revert") {
             return .revert
         } else {
             return .normal
         }
     }


}
