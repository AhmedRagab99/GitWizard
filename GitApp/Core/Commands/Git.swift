//
//  GitTypes.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

protocol Git {
    associatedtype OutputModel
    var arguments: [String] { get }
    var directory: URL { get }
    func parse(for output: String) throws -> OutputModel
}

// will be used in interactive commands
protocol InteractiveGit: Git {
    var inputs: [String] { get }
}


