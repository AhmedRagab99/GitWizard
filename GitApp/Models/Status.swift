//
//  Status.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct Status: Hashable {
    var untrackedFiles: [String]
    var untrackedFilesShortStat: String {
        if untrackedFiles.isEmpty {
            return ""
        } else if untrackedFiles.count == 1 {
            return "1 untracked file"
        } else {
            return "\(untrackedFiles.count) untracked files"
        }
    }
}
