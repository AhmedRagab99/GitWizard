//
//  SearchToken.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

enum SearchKind {
    case grep, grepAllMatch, s, g, author, revisionRange
}

struct SearchToken: Identifiable, Hashable {
    var id: Self { self }
    var kind: SearchKind
    var text: String
}
