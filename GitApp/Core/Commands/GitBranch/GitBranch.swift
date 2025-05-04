//
//  GitBranch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitBranch: Git {
    typealias OutputModel = [Branch]

    let directory: URL
    let isRemote: Bool

    init(directory: URL, isRemote: Bool = false) {
        self.directory = directory
        self.isRemote = isRemote
    }

    var arguments: [String] {
        var arg = [
            "git",
            "branch",
            "--sort=-authordate",
        ]
        if isRemote {
            arg.append("-r")
        }
        return arg
    }

    func parse(for stdOut: String) throws -> [Branch] {
        let lines = stdOut.components(separatedBy: .newlines).dropLast()
        return lines.map { line in
            Branch(name: String(line.dropFirst(2)), isCurrent: line.hasPrefix("*"))
        }
    }
}
