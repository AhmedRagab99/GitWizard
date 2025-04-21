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
        [
            "git",
            "restore",
            "--staged",
            "--patch",
        ]
    }
    var directory: URL
    var inputs: [String]

    func parse(for stdOut: String) -> Void {}
}