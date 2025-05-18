//
//  GitFetch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

final class GitFetch: Git {
    typealias OutputModel = Void

    var arguments: [String] {
        var args = ["git", "fetch"]

        // Add the remote if not fetching from all remotes
        if !fetchAllRemotes {
            args.append(remote)
        } else {
            args.append("--all")
        }

        // Add prune option if enabled
        if prune {
            args.append("--prune")
        }

        // Add tags option if enabled
        if fetchTags {
            args.append("--tags")
        }

        return args
    }

    var directory: URL
    var remote: String
    var fetchAllRemotes: Bool
    var prune: Bool
    var fetchTags: Bool

    init(
        directory: URL,
        remote: String = "origin",
        fetchAllRemotes: Bool = false,
        prune: Bool = false,
        fetchTags: Bool = false
    ) {
        self.directory = directory
        self.remote = remote
        self.fetchAllRemotes = fetchAllRemotes
        self.prune = prune
        self.fetchTags = fetchTags
    }

    func parse(for stdOut: String) -> Void {}
}
