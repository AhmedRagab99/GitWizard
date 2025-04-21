//
//  GitBranchDelete.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitBranchDelete: Git {
    var arguments: [String] {
        var arg = [
            "git",
            "branch",
            "--delete",
        ]
        if isRemote {
            arg.append("-r")
        }
        arg.append(branchName)
        return arg
    }
    var directory: URL
    var isRemote = false
    var branchName: String

    func parse(for stdOut: String) throws -> Void {}
}
