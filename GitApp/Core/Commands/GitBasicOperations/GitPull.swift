//
//  GitPull.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitPull: Git {
    typealias OutputModel = Void
    var directory: URL
    var remote: String
    var remoteBranch: String
    var localBranch: String
    var commitMerged: Bool
    var includeMessages: Bool
    var createNewCommit: Bool
    var rebaseInsteadOfMerge: Bool

    init(directory: URL, remote: String = "origin", remoteBranch: String = "", localBranch: String = "", commitMerged: Bool = false, includeMessages: Bool = false, createNewCommit: Bool = false, rebaseInsteadOfMerge: Bool = false) {
        self.directory = directory
        self.remote = remote
        self.remoteBranch = remoteBranch
        self.localBranch = localBranch
        self.commitMerged = commitMerged
        self.includeMessages = includeMessages
        self.createNewCommit = createNewCommit
        self.rebaseInsteadOfMerge = rebaseInsteadOfMerge
    }

    var arguments: [String] {
        var args: [String] = ["git", "pull", remote]
        if !remoteBranch.isEmpty {
            args.append(remoteBranch)
        }
        if !localBranch.isEmpty {
            args.append(":" + localBranch)
        }
        if rebaseInsteadOfMerge {
            args.append("--rebase")
        }
        if commitMerged {
            args.append("--commit")
        }
        if includeMessages {
            args.append("--log")
        }
        if createNewCommit {
            args.append("--no-ff")
        }
        return args
    }

    func parse(for output: String) throws -> Void {}
}
