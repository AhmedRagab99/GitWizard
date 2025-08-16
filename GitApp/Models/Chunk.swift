//
//  Chunk.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation
class Line: Identifiable, Hashable, Equatable {
    static func == (lhs: Line, rhs: Line) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    enum Kind {
        case removed, added, unchanged, header
        case conflictStart, conflictMiddle, conflictEnd, conflictOurs, conflictTheirs
    }
    var marker: String     // "+", "-", "<<<<<<<", etc.
    var id: Int
    var kind: Kind 
    var toFileLineNumber: Int?
    var raw: String
    var isInOurConflict: Bool = false
    var isInTheirConflict: Bool = false

    
    init(id: Int, raw: String, marker: String, kind: Kind) {
          self.id = id
          self.raw = raw
          self.marker = marker
          self.kind = kind
      }
}
class Chunk: Identifiable, Hashable {

    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(raw)
    }
    
    static func == (lhs: Chunk, rhs: Chunk) -> Bool {
        return lhs.raw == rhs.raw
    }
    
    
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

//    init(raw: String) {
//        let toFileRange = raw.split(separator: "+", maxSplits: 1)[safe: 1]?.split(separator: " ", maxSplits: 1)[safe: 0]
//        let splitedRange = toFileRange?.split(separator: ",", maxSplits: 1)
//        let startLine = splitedRange?[safe: 0].map { String($0) }
//        var currnetLine = startLine.map{ Int($0) } ?? nil
//
//        self.raw = raw
//        var linesArray = [Line]()
//        var inOurConflict = false
//        var inTheirConflict = false
//
//        let rawLines = raw.split(separator: "\n").enumerated()
//        for (offset, element) in rawLines {
//            let rawLine = String(element)
//            var line = Line(id: offset, raw: rawLine)
//
//            // A line is part of a conflict's content if the state is already set,
//            // but the line itself is not a marker.
//            if !rawLine.starts(with: "<<<<<<<") && !rawLine.starts(with: "=======") && !rawLine.starts(with: ">>>>>>>") {
//                line.isInOurConflict = inOurConflict
//                line.isInTheirConflict = inTheirConflict
//            }
//
//            // Update the state for subsequent lines based on markers.
//            if rawLine.starts(with: "<<<<<<<") {
//                inOurConflict = true
//                inTheirConflict = false
//            } else if rawLine.starts(with: "=======") {
//                inOurConflict = false
//                inTheirConflict = true
//            } else if rawLine.starts(with: ">>>>>>>") {
//                inOurConflict = false
//                inTheirConflict = false
//            }
//
//            // Set line numbers for non-conflict lines
//            switch line.kind {
//            case .removed:
//                break
//            case .added, .unchanged:
//                if let currnetLine1 = currnetLine {
//                    line.toFileLineNumber = currnetLine1
//                    currnetLine = currnetLine1 + 1
//                }
//            case .header, .conflictStart, .conflictMiddle, .conflictEnd, .conflictOurs, .conflictTheirs:
//                break
//            }
//
//            linesArray.append(line)
//        }
//
//        self.lines = linesArray
//        self.lineNumbers = linesArray.map({ line in
//            if let toFileLineNumber = line.toFileLineNumber {
//                return "\(toFileLineNumber)"
//            }
//            return ""
//        })
//    }
    
    
    init(raw: String) {
        let toFileRange = raw.split(separator: "+", maxSplits: 1)[safe: 1]?.split(separator: " ", maxSplits: 1)[safe: 0]
        let splitedRange = toFileRange?.split(separator: ",", maxSplits: 1)
        let startLine = splitedRange?[safe: 0].map { String($0) }
        var currnetLine = startLine.map { Int($0) } ?? nil

        self.raw = raw
        var linesArray = [Line]()
        var inOurConflict = false
        var inTheirConflict = false

        let rawLines = raw.split(separator: "\n").enumerated()
        for (offset, element) in rawLines {
            var text = String(element)
            var marker = " "
            var kind: Line.Kind = .unchanged

            if text.hasPrefix("<<<<<<<") {
                marker = "<<<<<<<"
                text = ""
                kind = .conflictStart
            } else if text.hasPrefix("=======") {
                marker = "======="
                text = ""
                kind = .conflictMiddle
            } else if text.hasPrefix(">>>>>>>") {
                marker = ">>>>>>>"
                text = ""
                kind = .conflictEnd
            } else if text.hasPrefix("+") {
                marker = "+"
                text.removeFirst()
                kind = .added
            } else if text.hasPrefix("-") {
                marker = "-"
                text.removeFirst()
                kind = .removed
            } else if text.hasPrefix("@") {
                marker = "@"
                kind = .header
            } else {
                marker = " "
                kind = .unchanged
            }

            var line = Line(id: offset, raw: text, marker: marker, kind: kind)

            // Update conflict state
            if !element.hasPrefix("<<<<<<<") && !element.hasPrefix("=======") && !element.hasPrefix(">>>>>>>") {
                line.isInOurConflict = inOurConflict
                line.isInTheirConflict = inTheirConflict
            }

            if element.hasPrefix("<<<<<<<") {
                inOurConflict = true
                inTheirConflict = false
            } else if element.hasPrefix("=======") {
                inOurConflict = false
                inTheirConflict = true
            } else if element.hasPrefix(">>>>>>>") {
                inOurConflict = false
                inTheirConflict = false
            }

            // Assign line numbers for added/unchanged
            switch kind {
            case .added, .unchanged:
                if let currentLine1 = currnetLine {
                    line.toFileLineNumber = currentLine1
                    currnetLine = currentLine1 + 1
                }
            default:
                break
            }

            linesArray.append(line)
        }

        self.lines = linesArray
        self.lineNumbers = linesArray.map { $0.toFileLineNumber.map(String.init) ?? "" }
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
