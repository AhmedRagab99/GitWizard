//
//  DiffStat.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct DiffStat {
    var files: [String]
    var insertions: [Int]
    var insertionsTotal: Int {
        insertions.reduce(0) { partialResult, e in
            partialResult + e
        }
    }
    var deletions: [Int]
    var deletionsTotal: Int {
        deletions.reduce(0) { partialResult, e in
            partialResult + e
        }
    }
}
