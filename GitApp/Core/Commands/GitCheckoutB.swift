//
//  GitCheckoutB.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitCheckoutB: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "checkout",
            "-b",
            newBranchName,
        ]

        // Add force flag if we need to discard local changes
        if discardLocalChanges {
            args.append("--force")
        }

        args.append("--track")
        args.append(startPoint)

        return args
    }
    var directory: URL
    var newBranchName: String
    var startPoint: String
    var discardLocalChanges: Bool = false

    func parse(for stdOut: String) -> Void {}
}
