//
//  GitStashDrop.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
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
