//
//  GitLog.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

 struct GitLog: Git {

    var directory: URL
    var merges = false
    var ancestryPath = false
    var reverse = false
    var number = 0
    var revisionRange = ""
    var grep: [String] = []
    var grepAllMatch = false
    var s = ""
    var g = ""
    var author = ""
    var branch = ""


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
        ]
        if merges {
            args.append("--merges")
        }
        if ancestryPath {
            args.append("--ancestry-path")
        }
        if reverse {
            args.append("--reverse")
        }
        if number > 0 {
            args.append("-\(number)")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        args = args + grep.map { "--grep=\($0)" }
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

             let hash  = separated[0]
             let parentHash = separated[1].components(separatedBy: .whitespacesAndNewlines)
             let author = separated[2]
             let authorEmail = separated[3]
             let authorDate = separated[4]
             let title = separated[5]
             let body = separated[6]
             let branches =  refs.filter { !$0.hasPrefix("tag: ") }
             let tags = refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
             // Generate avatar URL based on email (using Gravatar)
             let emailHash = authorEmail.lowercased().md5Hash
             let authorAvatar = "https://www.gravatar.com/avatar/\(emailHash)?d=identicon&s=40"
             return Commit(
                hash: hash,
                parentHashes: parentHash,
                author: author,
                authorEmail: authorEmail,
                authorDate: authorDate,
                 authorAvatar: authorAvatar,
                title: title,
                body: body,
                branches: branches,
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
