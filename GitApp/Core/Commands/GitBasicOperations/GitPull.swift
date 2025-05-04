//
//  GitPull.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

final class GitPull: Git {
    internal init(directory: URL, refspec: String) {
        self.directory = directory
        self.refspec = refspec
    }
    
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "pull",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec: String

    func parse(for stdOut: String) -> Void {}
}
