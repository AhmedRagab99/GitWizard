//
//  Chunk.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct Chunk: Identifiable, Hashable {
    struct Line: Identifiable, Hashable,Equatable {
        enum Kind {
            case removed, added, unchanged, header
        }
        var id: Int
        var kind: Kind {
            switch raw.first {
            case "-":
                return .removed
            case "+":
                return .added
            case " ":
                return .unchanged
            case "@":
                return .header
            default:
                return .unchanged
            }
        }
        var toFileLineNumber: Int?
        var raw: String

        init(id: Int, raw: String) {
            self.id = id
            self.raw = raw
        }
    }
    var id: String { raw }
    var lines: [Line]
    var lineNumbers: [String]
    var raw: String
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }
    var unstageString: String {
        if let stage, !stage {
            return "y"
        }
        return "n"
    }

    init(raw: String) {
        let toFileRange = raw.split(separator: "+", maxSplits: 1)[safe: 1]?.split(separator: " ", maxSplits: 1)[safe: 0]
        let splitedRange = toFileRange?.split(separator: ",", maxSplits: 1)
        let startLine = splitedRange?[safe: 0].map { String($0) }
        var currnetLine = startLine.map{ Int($0) } ?? nil

        self.raw = raw
        self.lines = raw.split(separator: "\n").enumerated().map {
            var line = Line(id: $0.offset, raw: String($0.element))
            switch line.kind {
            case .removed:
                break
            case .added:
                if let currnetLine1 = currnetLine {
                    line.toFileLineNumber = currnetLine1
                    currnetLine = currnetLine! + 1
                }
            case .unchanged:
                if let currnetLine1 = currnetLine {
                    line.toFileLineNumber = currnetLine1
                    currnetLine = currnetLine! + 1
                }
            case .header:
                break
            }
            return line
        }
        self.lineNumbers = lines.map({ line in
            if let toFileLineNumber = line.toFileLineNumber {
                return "\(toFileLineNumber)"
            }
            return ""
        })
    }
}
