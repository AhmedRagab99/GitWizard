//
//  GitDiffNumStat.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitDiffNumStat: Git {
    typealias OutputModel = DiffStat
    var arguments: [String] {
        var args = [
           "git",
           "diff",
           "--no-renames",
           "--numstat",
        ]
        if cached {
            args.append("--cached")
        }
        return args
    }
    var directory: URL
    var cached = false

    func parse(for stdOut: String) -> DiffStat {
        let lines = stdOut.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let splitted = lines.map { line in
            line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        }
        return DiffStat(
            files: splitted.map { String($0[safe: 2] ?? "") },
            insertions: splitted.map { Int($0[safe: 0] ?? "0") ?? 0 },
            deletions: splitted.map { Int($0[safe: 1] ?? "0") ?? 0 }
        )
    }
}
