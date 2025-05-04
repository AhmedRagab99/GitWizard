//
//  GitCommit.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitCommit: Git {
    typealias OutputModel = Void

    let directory: URL
    let message: String

    init(directory: URL, message: String) {
        self.directory = directory
        self.message = message
    }

    var arguments: [String] {
        [
            "git",
            "commit",
            "-m",
            message,
        ]
    }

    func parse(for stdOut: String) -> Void {}
}
