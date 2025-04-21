//
//  GitPush.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitPush: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "push",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec = "HEAD"

    func parse(for stdOut: String) -> Void {}
}
