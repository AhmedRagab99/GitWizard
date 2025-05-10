//
//  GitPush.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitPush: Git {
    typealias OutputModel = Void
    var directory: URL
    var refspec = "HEAD"
    var pushTags: Bool = false

    var arguments: [String] {
        var args: [String] = [
            "git",
            "push",
            "origin",
            refspec,
        ]
        if pushTags {
            args.append("--tags")
        }
        return args
    }

    func parse(for stdOut: String) -> Void {}
}
