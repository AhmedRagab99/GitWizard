//
//  GitStashList.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import Foundation

struct GitStashList: Git {
    typealias OutputModel = [Stash]
    let arguments = [
        "git",
        "stash",
        "list"
    ]
    var directory: URL

    func parse(for stdOut: String) throws -> [Stash] {
        guard !stdOut.isEmpty else { return [] }
        let stashList = stdOut.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return stashList.enumerated().map { i, stash in
            return Stash(index: i, raw: stash)
        }
    }
}
