//
//  GitRestore.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitRestore: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "restore",
            "--staged",
            ".",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
