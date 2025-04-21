//
//  GitMerge.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//
import Foundation

struct GitMerge: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "merge",
            branchName,
        ]
    }
    var directory: URL
    var branchName: String

    func parse(for stdOut: String) -> Void {}
}
