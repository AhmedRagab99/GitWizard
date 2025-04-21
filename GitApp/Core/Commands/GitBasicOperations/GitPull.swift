//
//  GitPull.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitPull: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "pull",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec: String

    func parse(for stdOut: String) -> Void {}
}
