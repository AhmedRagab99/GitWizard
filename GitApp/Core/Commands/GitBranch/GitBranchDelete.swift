//
//  GitBranchDelete.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitBranchDelete: Git {
    var arguments: [String] {
        if isRemote {
            // For remote branches, we need to push the delete to the remote
            return [
                "git",
                "push",
                "origin",
                "--delete",
                branchName.replacingOccurrences(of: "origin/", with: "") // Remove origin/ prefix if present
            ]
        } else {
            // For local branches, use the standard branch delete command
            return [
                "git",
                "branch",
                "--delete",
                branchName
            ]
        }
    }
    var directory: URL
    var isRemote = false
    var branchName: String

    func parse(for stdOut: String) throws -> Void {}
}
