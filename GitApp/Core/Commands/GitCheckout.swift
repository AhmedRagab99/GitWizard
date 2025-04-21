//
//  GitCheckout.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//
import Foundation

struct GitCheckout: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "checkout",
            commitHash,
        ]
    }
    var directory: URL
    var commitHash: String

    func parse(for stdOut: String) -> Void {}
}
