//
//  LineChange.swift
//  GitApp
//
//  Created by Ahmed Ragab on 19/04/2025.
//


import Foundation
struct LineChange: Identifiable, Hashable {
    let id: UUID
    let lineNumber: Int
    let content: String
    let type: ChangeType

    enum ChangeType: String {
        case added = "+"
        case removed = "-"
        case unchanged = " "
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LineChange, rhs: LineChange) -> Bool {
        lhs.id == rhs.id
    }
}
