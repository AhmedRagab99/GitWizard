//
//  Status.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

class Status: Hashable {
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: Status, rhs: Status) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = UUID()
    var untrackedFiles: [String] = []
    var conflicted: [String] = []

    var untrackedFilesShortStat: String {
        if untrackedFiles.isEmpty {
            return ""
        } else if untrackedFiles.count == 1 {
            return "1 untracked file"
        } else {
            return "\(untrackedFiles.count) untracked files"
        }
    }

    var conflictedFilesShortStat: String {
        if conflicted.isEmpty {
            return ""
        } else if conflicted.count == 1 {
            return "1 file with conflicts"
        } else {
            return "\(conflicted.count) files with conflicts"
        }
    }

    var hasConflicts: Bool {
        return !conflicted.isEmpty
    }
}
