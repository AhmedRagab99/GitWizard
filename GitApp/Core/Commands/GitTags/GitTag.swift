//
//  GitTag.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitTag: Git {
    typealias OutputModel = [String]
    var arguments: [String] {
        [
            "git",
            "tag",
            "--no-column",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> [String] {
        stdOut.components(separatedBy: .newlines).dropLast()
    }
}
