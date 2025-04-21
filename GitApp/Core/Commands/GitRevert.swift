//
//  GitRevert.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitRevert: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "revert",
        ]
        if let parentNumber {
            args.append("-m")
            args.append(String(parentNumber))
        }
        args.append(commit)
        return args
    }
    var directory: URL
    var parentNumber: Int?
    /// Commits to revert. For a more complete list of ways to spell commit names, see gitrevisions[7]. Sets of commits can also be given but no traversal is done by default, see git-rev-list[1] and its --no-walk option.
    var commit: String

    func parse(for stdOut: String) -> Void {}
}
