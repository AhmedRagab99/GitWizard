//
//  GitAddPathspec.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitAddPathspec: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "add",
            pathspec,
        ]
    }
    var directory: URL
    var pathspec: String

    func parse(for stdOut: String) -> Void {}
}