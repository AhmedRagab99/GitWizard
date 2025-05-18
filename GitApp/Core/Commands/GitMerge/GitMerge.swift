//
//  GitMerge.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//
import Foundation

struct GitMerge: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "merge",
        ]

        // Add options based on the merge options
        if commitMerged {
            args.append("--commit")
        } else {
            args.append("--no-commit")
        }

        if includeMessages {
            args.append("--log")
        }

        if createNewCommit {
            args.append("--no-ff")
        }

        if rebaseInsteadOfMerge {
            return ["git", "rebase", branchName]
        }

        // Add the branch name last
        args.append(branchName)

        return args
    }

    var directory: URL
    var branchName: String
    var commitMerged: Bool
    var includeMessages: Bool
    var createNewCommit: Bool
    var rebaseInsteadOfMerge: Bool

    init(
        directory: URL,
        branchName: String,
        commitMerged: Bool = true,
        includeMessages: Bool = false,
        createNewCommit: Bool = false,
        rebaseInsteadOfMerge: Bool = false
    ) {
        self.directory = directory
        self.branchName = branchName
        self.commitMerged = commitMerged
        self.includeMessages = includeMessages
        self.createNewCommit = createNewCommit
        self.rebaseInsteadOfMerge = rebaseInsteadOfMerge
    }

    func parse(for stdOut: String) -> Void {}
}
