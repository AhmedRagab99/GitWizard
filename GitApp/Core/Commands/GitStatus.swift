//
//  GitStatus.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitStatus: Git {
    typealias OutputModel = Status
    var arguments: [String] {
        [
            "git",
            "status",
            "--porcelain",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> Status {
        let lines = stdOut.components(separatedBy: .newlines)
        let untrackedFiles = lines
            .filter { $0.hasPrefix("?? ") }
            .map { String($0.dropFirst(3)) }
        return Status(untrackedFiles: untrackedFiles)
    }
}
