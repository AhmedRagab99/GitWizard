//
//  GitStash.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
//

import Foundation

final class GitStash: Git {
    typealias OutputModel = Void

    let directory: URL
    let message: String

    init(directory: URL, message: String = "") {
        self.directory = directory
        self.message = message
    }

    var arguments: [String] {
        var args = [
            "git",
            "stash",
            "--include-untracked",
        ]
        if !message.isEmpty {
            args.append("-m")
            args.append(message)
        }
        return args
    }

    func parse(for stdOut: String) -> Void {}
}
