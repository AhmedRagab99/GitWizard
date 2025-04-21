//
//  GitTagDelete.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitTagDelete: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "tag",
            "-d",
            tagname,
        ]
    }
    var directory: URL
    var tagname: String

    func parse(for stdOut: String) throws -> OutputModel {}
}
