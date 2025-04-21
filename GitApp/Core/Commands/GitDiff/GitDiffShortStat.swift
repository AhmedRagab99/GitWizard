//
//  GitDiffShortStat.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitDiffShortStat: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
           "git",
           "diff",
           "--no-renames",
           "--shortstat",
        ]
        if cached {
            args.append("--cached")
        }
        return args
    }
    var directory: URL
    var cached = false

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
