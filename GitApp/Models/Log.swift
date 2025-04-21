//
//  Log.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

enum Log: Identifiable, Hashable {
    var id: String {
        switch self {
        case .notCommitted:
            return "notCommitted"
        case .committed(let c):
            return c.hash
        }
    }

    case notCommitted, committed(Commit)
}

struct NotCommitted: Hashable {
    var diff: String
    var diffCached: String
    var status: Status
    var isEmpty: Bool { (diff + diffCached).isEmpty && status.untrackedFiles.isEmpty }
}