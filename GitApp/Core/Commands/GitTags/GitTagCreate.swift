//
//  GitTagCreate.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitTagCreate: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "tag",
            tagname,
            object,
        ]
    }
    var directory: URL
    var tagname: String
    var object: String

    func parse(for stdOut: String) throws -> OutputModel {}
}
