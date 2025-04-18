//
//  FileType.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import Foundation
import SwiftUI

enum FileType {
    case swift
    case markdown
    case json
    case yaml
    case gitignore
    case other(String)

    init(from filename: String) {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": self = .swift
        case "md": self = .markdown
        case "json": self = .json
        case "yml", "yaml": self = .yaml
        case "":
            if filename.lowercased() == ".gitignore" {
                self = .gitignore
            } else {
                self = .other("")
            }
        default: self = .other(ext)
        }
    }

    var icon: String {
        switch self {
        case .swift: return "swift"
        case .markdown: return "doc.text"
        case .json: return "curlybraces"
        case .yaml: return "list.bullet.indent"
        case .gitignore: return "eye.slash"
        case .other: return "doc"
        }
    }

    var color: Color {
        switch self {
        case .swift: return .orange
        case .markdown: return .blue
        case .json: return .yellow
        case .yaml: return .green
        case .gitignore: return .gray
        case .other: return .secondary
        }
    }

    var label: String {
        switch self {
        case .swift: return "Swift"
        case .markdown: return "Markdown"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .gitignore: return "GitIgnore"
        case .other(let ext): return ext.uppercased()
        }
    }
}

