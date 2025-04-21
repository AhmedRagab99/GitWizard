//
//  Language.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation
import Sourceful
import SwiftUI

enum Language: String {
    
    case swift, python, javascript, typescript, java, kotlin, c, cpp, csharp, ruby, php, go, rust, shell, perl, html, css, markdown, ocaml, gitignore,other

    private static func detect(filePath: String) -> Language? {
        let ext = URL(fileURLWithPath: String(filePath)).pathExtension.lowercased()

        switch ext {
        case "swift": return .swift
        case "py": return .python
        case "js": return .javascript
        case "ts": return .typescript
        case "java": return .java
        case "kt": return .kotlin
        case "c": return .c
        case "cpp", "cc", "cxx": return .cpp
        case "cs": return .csharp
        case "rb": return .ruby
        case "php": return .php
        case "go": return .go
        case "rs": return .rust
        case "sh", "bash", "zsh": return .shell
        case "pl": return .perl
        case "html": return .html
        case "css": return .css
        case "md": return .markdown
        case "ml": return .ocaml
        case "gitigonre" : return .gitignore
        default: return .other
        }
    }

    static func lexer(filePath: String) -> Lexer {
        switch detect(filePath: filePath) {
        case .java:
            return JavaLexer()
        case .javascript, .typescript:
            return JavaScriptLexer()
        case .python:
            return Python3Lexer()
        case .swift:
            return SwiftLexer()
        case .ocaml:
            return OCamlLexer()
        default:
            return PlainLexer()
        }
    }
    static func label(filePath: String) -> String? {        
        switch detect(filePath: filePath) {
        case .swift:
            return "Swift"
        case .javascript:
            return "JavaScript"
        case .python:
            return "Python"
        case .ocaml:
            return "OCaml"
        case .java:
            return "Java"
        case .typescript:
            return "TypeScript"
        case .markdown:
            return "Markdown"
        case .ruby:
            return "Ruby"
        case .rust:
            return "Rust"
        case .gitignore:
            return "GitIgnore"
        case .other:
            let ext = URL(fileURLWithPath: String(filePath)).pathExtension.lowercased()
            return filePath
        default:
            let ext = URL(fileURLWithPath: String(filePath)).pathExtension.lowercased()
            return nil
        }
    }

    static func assetName(filePath: String) -> String? {
        switch detect(filePath: filePath) {
        case .swift:
            return "Swift"
        case .python:
            return "python"
        case .ruby:
            return "ruby"
        case .rust:
            return "rust"
        case .javascript:
            return "js"
        case .ocaml:
            return "ocaml"
        default:
            return nil
            
        }
    }
}
//import Foundation
//import SwiftUI
//
//enum FileType {
//    case swift
//    case markdown
//    case json
//    case yaml
//    case gitignore
//    case other(String)
//
//    init(from filename: String) {
//        let ext = (filename as NSString).pathExtension.lowercased()
//        switch ext {
//        case "swift": self = .swift
//        case "md": self = .markdown
//        case "json": self = .json
//        case "yml", "yaml": self = .yaml
//        case "":
//            if filename.lowercased() == ".gitignore" {
//                self = .gitignore
//            } else {
//                self = .other("")
//            }
//        default: self = .other(ext)
//        }
//    }
//
//    var icon: String {
//        switch self {
//        case .swift: return "swift"
//        case .markdown: return "doc.text"
//        case .json: return "curlybraces"
//        case .yaml: return "list.bullet.indent"
//        case .gitignore: return "eye.slash"
//        case .other: return "doc"
//        }
//    }
//
//    var color: Color {
//        switch self {
//        case .swift: return .orange
//        case .markdown: return .blue
//        case .json: return .yellow
//        case .yaml: return .green
//        case .gitignore: return .gray
//        case .other: return .secondary
//        }
//    }
//
//    var label: String {
//        switch self {
//        case .swift: return "Swift"
//        case .markdown: return "Markdown"
//        case .json: return "JSON"
//        case .yaml: return "YAML"
//        case .gitignore: return "GitIgnore"
//        case .other(let ext): return ext.uppercased()
//        }
//    }
//}
