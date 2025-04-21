//
//  GitBranch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//



import Foundation

struct GitBranch: Git {
    typealias OutputModel = [Branch]
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
    var directory: URL
    var isRemote = false

    func parse(for stdOut: String) throws -> [Branch] {
        let lines = stdOut.components(separatedBy: .newlines).dropLast()
        return lines.map { line in
            Branch(name: String(line.dropFirst(2)), isCurrent: line.hasPrefix("*"))
        }
    }
}
