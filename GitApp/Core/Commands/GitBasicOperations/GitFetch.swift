//
//  GitFetch.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

final class GitFetch: Git {
    internal init(arguments: [String] = [
        "git",
        "fetch",
    ], directory: URL) {
        self.arguments = arguments
        self.directory = directory
    }
    
    typealias OutputModel = Void
    var arguments = [
        "git",
        "fetch",
    ]
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
