//
//  GitStashApply.swift
//  GitClient
//
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
