//
//  GitTag.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitTag: Git {
    typealias OutputModel = [String]

    let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    var arguments: [String] {
        [
            "git",
            "tag",
            "--no-column",
        ]
    }

    func parse(for stdOut: String) throws -> [String] {
        stdOut.components(separatedBy: .newlines).dropLast()
    }
}
