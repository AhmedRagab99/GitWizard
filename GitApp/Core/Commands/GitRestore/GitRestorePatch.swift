//
//  GitRestorePatch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitRestorePatch: InteractiveGit {
    typealias OutputModel = Void
    var arguments: [String] {
        var args = [
            "git",
            "restore",
            "--staged",
            "--patch"
        ]

        if let path = filePath {
            args.append(path)
        }

        return args
    }
    var directory: URL
    var inputs: [String]
    var filePath: String?

    init(directory: URL, inputs: [String], filePath: String? = nil) {
        self.directory = directory
        self.inputs = inputs
        self.filePath = filePath
    }

    func parse(for stdOut: String) -> Void {}
}
