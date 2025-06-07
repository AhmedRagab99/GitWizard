//
//  GitStashDrop.swift
//  GitClient
//
//

import Foundation

struct GitStashDrop: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "stash",
            "drop",
            "\(index)"
        ]
    }
    var directory: URL
    var index: Int

    func parse(for stdOut: String) -> Void {}
}
