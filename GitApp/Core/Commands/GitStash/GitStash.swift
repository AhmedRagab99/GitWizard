//
//  GitStash.swift
//  GitClient
//
//

import Foundation

final class GitStash: Git {
    typealias OutputModel = Void

    let directory: URL
    let message: String
    let keepStaged: Bool

    init(directory: URL, message: String = "", keepStaged: Bool = false) {
        self.directory = directory
        self.message = message
        self.keepStaged = keepStaged
    }

    var arguments: [String] {
        var args = [
            "git",
            "stash",
            "--include-untracked",
        ]
        if keepStaged {
            args.append("--keep-index")
        }
        if !message.isEmpty {
            args.append("-m")
            args.append(message)
        }
        return args
    }

    func parse(for stdOut: String) -> Void {}
}
