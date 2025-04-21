//
//  GitShowShortstat.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitShowShortstat: Git {
    var arguments: [String] {
        [
            "git",
            "show",
            "--shortstat",
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> String {
        guard !stdOut.isEmpty else { throw GenericError(errorDescription: "Parse error: stdOut is empty.") }
        return String(stdOut.split(separator: "\n").last ?? "").trimmingCharacters(in: .whitespaces)
    }
}
