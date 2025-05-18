//
//  GitCheckout.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//
import Foundation

struct GitCheckout: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "checkout",
        ]

        // Add force flag if we need to discard local changes
        if discardLocalChanges {
            args.append("--force")
        }

        args.append(commitHash)
        return args
    }
    var directory: URL
    var commitHash: String
    var discardLocalChanges: Bool = false

    func parse(for stdOut: String) -> Void {}
}
