//
//  GitSwitch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitSwitch: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "switch",
        ]

        // Add discard local changes flag if requested
        if discardLocalChanges {
            args.append("--discard-changes")
        }

        args.append(branchName)
        return args
    }
    var directory: URL
    var branchName: String
    var discardLocalChanges: Bool = false

    func parse(for stdOut: String) -> Void {}
}
