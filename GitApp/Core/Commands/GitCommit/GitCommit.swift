//
//  GitCommit.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitCommit: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "commit",
            "-m",
            message,
        ]
    }
    var directory: URL
    var message: String

    func parse(for stdOut: String) -> Void {}
}
