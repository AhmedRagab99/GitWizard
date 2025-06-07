//
//  Chunk.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation
struct Line: Identifiable, Hashable, Equatable {
    enum Kind {
        case removed, added, unchanged, header
        case conflictStart, conflictMiddle, conflictEnd, conflictOurs, conflictTheirs
    }
    var id: Int
    var kind: Kind {
        if raw.starts(with: "<<<<<<<") {
            return .conflictStart
        } else if raw.starts(with: "=======") {
            return .conflictMiddle
        } else if raw.starts(with: ">>>>>>>") {
            return .conflictEnd
        } else if isInOurConflict {
            return .conflictOurs
        } else if isInTheirConflict {
            return .conflictTheirs
        } else {
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
    }
    var toFileLineNumber: Int?
    var raw: String
    var isInOurConflict: Bool = false
    var isInTheirConflict: Bool = false

    init(id: Int, raw: String) {
        self.id = id
        self.raw = raw
    }
}
struct Chunk: Identifiable, Hashable {

    var id: String { raw }
    var lines: [Line]
    var lineNumbers: [String]
    var raw: String
    var stage: Bool?

    // The header is the first line of the chunk (@@... @@ line)
    var header: String {
        if let firstLine = raw.split(separator: "\n").first {
            return String(firstLine)
        }
        return ""
    }

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

    // Check if this chunk has a conflict
    var hasConflict: Bool {
        return lines.contains {
            $0.kind == .conflictStart || $0.kind == .conflictMiddle || $0.kind == .conflictEnd
        }
    }

    // Get conflict sections for resolution
    var oursConflict: [Line] {
        guard hasConflict else { return [] }
        var result: [Line] = []
        var inOursSection = false

        for line in lines {
            if line.kind == .conflictStart {
                inOursSection = true
                continue
            }
            if line.kind == .conflictMiddle {
                inOursSection = false
                continue
            }
            if inOursSection {
                result.append(line)
            }
        }

        return result
    }

    var theirsConflict: [Line] {
        guard hasConflict else { return [] }
        var result: [Line] = []
        var inTheirsSection = false

        for line in lines {
            if line.kind == .conflictMiddle {
                inTheirsSection = true
                continue
            }
            if line.kind == .conflictEnd {
                inTheirsSection = false
                continue
            }
            if inTheirsSection {
                result.append(line)
            }
        }

        return result
    }

    init(raw: String) {
        let toFileRange = raw.split(separator: "+", maxSplits: 1)[safe: 1]?.split(separator: " ", maxSplits: 1)[safe: 0]
        let splitedRange = toFileRange?.split(separator: ",", maxSplits: 1)
        let startLine = splitedRange?[safe: 0].map { String($0) }
        var currnetLine = startLine.map{ Int($0) } ?? nil

        self.raw = raw
        var linesArray = [Line]()
        var inOurConflict = false
        var inTheirConflict = false

        let rawLines = raw.split(separator: "\n").enumerated()
        for (offset, element) in rawLines {
            var line = Line(id: offset, raw: String(element))

            // Handle conflict markers
            if line.raw.starts(with: "<<<<<<<") {
                inOurConflict = true
                inTheirConflict = false
            } else if line.raw.starts(with: "=======") {
                inOurConflict = false
                inTheirConflict = true
            } else if line.raw.starts(with: ">>>>>>>") {
                inOurConflict = false
                inTheirConflict = false
            }

            // Set conflict section flags
            line.isInOurConflict = inOurConflict
            line.isInTheirConflict = inTheirConflict

            // Set line numbers for non-conflict lines
            switch line.kind {
            case .removed:
                break
            case .added, .unchanged:
                if let currnetLine1 = currnetLine {
                    line.toFileLineNumber = currnetLine1
                    currnetLine = currnetLine1 + 1
                }
            case .header, .conflictStart, .conflictMiddle, .conflictEnd, .conflictOurs, .conflictTheirs:
                break
            }

            linesArray.append(line)
        }

        self.lines = linesArray
        self.lineNumbers = linesArray.map({ line in
            if let toFileLineNumber = line.toFileLineNumber {
                return "\(toFileLineNumber)"
            }
            return ""
        })
    }

    // Resolve conflict using "ours" (our changes)
    func resolveUsingOurs() -> Chunk {
        guard hasConflict else { return self }

        var newLines = [Line]()
        var skipSection = false
        var inConflict = false

        for (index, line) in lines.enumerated() {
            if line.kind == .conflictStart {
                inConflict = true
                skipSection = false
                continue
            }

            if line.kind == .conflictMiddle {
                skipSection = true
                continue
            }

            if line.kind == .conflictEnd {
                inConflict = false
                skipSection = false
                continue
            }

            if !inConflict || (inConflict && !skipSection) {
                var newLine = line
                newLine.isInOurConflict = false
                newLine.isInTheirConflict = false
                newLine.id = newLines.count
                newLines.append(newLine)
            }
        }

        var newChunk = self
        newChunk.lines = newLines
        return newChunk
    }

    // Resolve conflict using "theirs" (their changes)
    func resolveUsingTheirs() -> Chunk {
        guard hasConflict else { return self }

        var newLines = [Line]()
        var skipSection = true
        var inConflict = false

        for (index, line) in lines.enumerated() {
            if line.kind == .conflictStart {
                inConflict = true
                skipSection = true
                continue
            }

            if line.kind == .conflictMiddle {
                skipSection = false
                continue
            }

            if line.kind == .conflictEnd {
                inConflict = false
                skipSection = false
                continue
            }

            if !inConflict || (inConflict && !skipSection) {
                var newLine = line
                newLine.isInOurConflict = false
                newLine.isInTheirConflict = false
                newLine.id = newLines.count
                newLines.append(newLine)
            }
        }

        var newChunk = self
        newChunk.lines = newLines
        return newChunk
    }
}
