//
//  SyncState.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import SwiftUI


@Observable
class SyncState {
    var folderURL: URL?
    var branch: Branch?
    var shouldPull = false
    var shouldPush = false
    var commitsAhead: Int? = nil

    func sync() async throws {
        guard let folderURL, let branch, !branch.isDetached else {
            shouldPull = false
            shouldPush = false
            commitsAhead = nil
            return
        }
        try await Process.output(GitFetch(directory: folderURL))

        let existRemoteBranch = try? await Process.output(GitShowref(directory: folderURL, pattern: "refs/remotes/origin/\(branch.name)"))
        guard existRemoteBranch != nil else {
            shouldPull = false
            shouldPush = true
            commitsAhead = nil
            return
        }
        let aheadCommits = try await Process.output(GitLog(directory: folderURL, number: 30, revisionRange: "origin/\(branch.name)..\(branch.name)"))
        commitsAhead = aheadCommits.count
        shouldPull = !(try await Process.output(GitLog(directory: folderURL, revisionRange: "\(branch.name)..origin/\(branch.name)")).isEmpty)
        shouldPush = !(aheadCommits.isEmpty)
    }
}
