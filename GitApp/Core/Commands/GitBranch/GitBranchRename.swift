//
//  GitBranchRename.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitBranchRename: Git {
    var arguments: [String] {
        var arg = [
            "git",
            "branch",
            "-m",
        ]
        arg.append(oldBranchName)
        arg.append(newBranchName)
        return arg
    }
    var directory: URL
    var oldBranchName: String
    var newBranchName: String

    func parse(for stdOut: String) throws -> Void {}
}
