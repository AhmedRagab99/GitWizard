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
        [
            "git",
            "checkout",
            "-b",
            newBranchName,
            "--track",
            startPoint,
        ]
    }
    var directory: URL
    var newBranchName: String
    var startPoint: String

    func parse(for stdOut: String) -> Void {}
}
