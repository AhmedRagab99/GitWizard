//
//  GitStashApply.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/16.
//

import Foundation

struct GitStashApply: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "stash",
            "apply",
            "\(index)"
        ]
    }
    var directory: URL
    var index: Int

    func parse(for stdOut: String) -> Void {}
}
