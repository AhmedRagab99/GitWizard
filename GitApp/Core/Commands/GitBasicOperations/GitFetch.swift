//
//  GitFetch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

struct GitFetch: Git {
    typealias OutputModel = Void
    var arguments = [
        "git",
        "fetch",
    ]
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}