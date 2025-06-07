//
//  FileDiff.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation
import SwiftUI
enum FileStatus: String {
    case modified = "Modified"
    case added = "Added"
    case removed = "Removed"
    case renamed = "Renamed"
    case copied = "Copied"
    case unknown = "Unknown"
    case untracked = "Untracked"
    case ignored = "Ignored"
    case deleted = "Deleted"
    case conflict = "Conflict"

    // File status codes from git
    static func fromGitStatus(_ status: String) -> FileStatus {
        switch status {
        case "M": return .modified
        case "A": return .added
        case "D": return .deleted
        case "R": return .renamed
        case "C": return .copied
        case "?": return .untracked
        case "!": return .ignored
        case "U": return .conflict
        default: return .unknown
        }
    }

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .untracked: return "questionmark.circle.fill"
        case .ignored: return "questionmark.circle.fill"
        case .copied: return "doc.on.doc.fill"
        case .removed: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        case .conflict: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .renamed: return .orange
        case .untracked: return .gray
        case .ignored: return .gray
        case .removed: return .red
        case .copied: return .yellow
        case .unknown: return .purple
        case .conflict: return .purple
        }
    }

    var shortDescription: String {
        switch self {
        case .modified: return "M"
        case .added: return "A"
        case .removed: return "R"
        case .renamed: return "Ren"
        case .copied: return "C"
        case .unknown: return "?"
        case .untracked: return "U"
        case .ignored: return "I"
        case .deleted: return "D"
        case .conflict: return "!"
        }
    }
}

struct FileDiff: Identifiable, Hashable {
    var id: String { raw }
    var header: String
    var status: FileStatus

    private static func calculateStatus(header: String, fromFilePath: String, toFilePath: String, chunks: [Chunk], extendedHeaderLines: [String], fromFileToFileLines: [String]) -> FileStatus {
        // Check for conflicts in chunks first, as this is the most specific status
        if chunks.contains(where: { $0.hasConflict }) {
            return .conflict
        }

        // Check if header contains file mode information that indicates file status
        if header.contains("new file mode") {
            return .added
        } else if header.contains("deleted file mode") {
            return .removed
        } else if fromFilePath.isEmpty && !toFilePath.isEmpty {
            return .added
        } else if !fromFilePath.isEmpty && toFilePath.isEmpty {
            return .removed
        } else if fromFilePath != toFilePath {
            return .renamed
        } else {
            // For binary files or renames, check extended header info
            for line in extendedHeaderLines {
                if line.contains("new file") {
                    return .added
                } else if line.contains("deleted file") {
                    return .removed
                }
            }

            // Check for /dev/null which indicates added or removed files
            if fromFileToFileLines.contains(where: { $0.contains("/dev/null") }) {
                if fromFileToFileLines.first(where: { $0.hasPrefix("--- ") })?.contains("/dev/null") ?? false {
                    return .added
                } else if fromFileToFileLines.first(where: { $0.hasPrefix("+++ ") })?.contains("/dev/null") ?? false {
                    return .removed
                }
            }

            return .modified
        }
    }

    var fromFilePath: String {
        let components = header.components(separatedBy: " ")
        guard components.count > 2 else {
            return ""
        }
        let filePath = components[2].dropFirst(2)
        return String(filePath)
    }

    var toFilePath: String {
        let components = header.components(separatedBy: " ")
        guard components.count > 3 else {
            return ""
        }
        let filePath = components[3].dropFirst(2)
        return String(filePath)
    }

    var filePathDisplay: String {
        if fromFilePath == toFilePath {
            return fromFilePath
        }
        if !fromFilePath.isEmpty && !toFilePath.isEmpty && fromFilePath != toFilePath {
            return fromFilePath + " => " + toFilePath
        }
        return ""
    }

    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var chunks: [Chunk]
    var stage: Bool? = nil
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
    var raw: String

    var lineStats: (added: Int, removed: Int) {
        let added = chunks.flatMap { $0.lines }.filter { $0.kind == .added }.count
        let removed = chunks.flatMap { $0.lines }.filter { $0.kind == .removed }.count
        return (added, removed)
    }

    private static func extractChunks(from lines: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: String?

        for line in lines {
            if line.starts(with: "@@") {
                if let hunk = currentChunk {
                    chunks.append(hunk)
                }
                currentChunk = line
            } else {
                currentChunk?.append("\n" + line)
            }
        }

        if let lastHunk = currentChunk {
            chunks.append(lastHunk)
        }

        return chunks
    }

    init(raw: String) throws {
        self.raw = raw
        let splited = raw.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let firstLine = splited.first
        guard let firstLine else {
            throw GenericError(errorDescription: "Parse error for first line in FileDiff")
        }
        self.header = firstLine

        let fromFileIndexOptional = splited.firstIndex { $0.hasPrefix("--- ") }

        if let fromFileIndex = fromFileIndexOptional {
            self.extendedHeaderLines = splited[1..<fromFileIndex].map { String($0) }
            let toFileIndex = splited.lastIndex { $0.hasPrefix("+++ ") }
            guard let toFileIndex else {
                throw GenericError(errorDescription: "Parse error for toFileIndex in FileDiff")
            }
            self.fromFileToFileLines = splited[fromFileIndex...toFileIndex].map { String($0) }
            self.chunks = Self.extractChunks(from: splited).map { Chunk(raw: $0) }
        } else {
            self.extendedHeaderLines = splited.count > 1 ? splited[1...].map { String($0) } : []
            self.fromFileToFileLines = []
            self.chunks = []
        }

        // Manually calculate paths inside the initializer to avoid using `self` before all stored properties are set.
        let headerComponents = self.header.components(separatedBy: " ")
        let localFromFilePath = (headerComponents.count > 2) ? String(headerComponents[2].dropFirst(2)) : ""
        let localToFilePath = (headerComponents.count > 3) ? String(headerComponents[3].dropFirst(2)) : ""

        self.status = FileDiff.calculateStatus(
            header: self.header,
            fromFilePath: localFromFilePath,
            toFilePath: localToFilePath,
            chunks: self.chunks,
            extendedHeaderLines: self.extendedHeaderLines,
            fromFileToFileLines: self.fromFileToFileLines
        )
    }

    // Init from untracked file
    init(untrackedFile path: String) {
        self.raw = "diff --git a/\(path) b/\(path)\nnew file mode 100644"
        self.header = "diff --git a/\(path) b/\(path)"
        self.extendedHeaderLines = ["new file mode 100644"]
        self.fromFileToFileLines = []
        self.chunks = []
        self.status = .untracked
    }

    // Init for added files
    init(added path: String) {
        self.raw = "diff --git a/\(path) b/\(path)\nnew file mode 100644\n--- /dev/null\n+++ b/\(path)"
        self.header = "diff --git a/\(path) b/\(path)"
        self.extendedHeaderLines = ["new file mode 100644"]
        self.fromFileToFileLines = ["--- /dev/null", "+++ b/\(path)"]
        self.chunks = []
        self.status = .added
    }

    // Init for removed files
    init(removed path: String) {
        self.raw = "diff --git a/\(path) b/\(path)\ndeleted file mode 100644\n--- a/\(path)\n+++ /dev/null"
        self.header = "diff --git a/\(path) b/\(path)"
        self.extendedHeaderLines = ["deleted file mode 100644"]
        self.fromFileToFileLines = ["--- a/\(path)", "+++ /dev/null"]
        self.chunks = []
        self.status = .removed
    }

    // Init for binary files
    init(binary path: String) {
        self.raw = "diff --git a/\(path) b/\(path)\nBinary files differ"
        self.header = "diff --git a/\(path) b/\(path)"
        self.extendedHeaderLines = ["Binary files differ"]
        self.fromFileToFileLines = []
        self.chunks = []
        self.status = .modified
    }

    // Init from fileDiffs and mappingLines - useful for constructing diffs programmatically
    init(fileDiffs: [Chunk], mappingLines: [Int: Int], diffText: String) {
        self.raw = diffText
        self.header = diffText.components(separatedBy: "\n").first ?? ""
        self.extendedHeaderLines = []
        self.fromFileToFileLines = []
        self.chunks = fileDiffs
        self.status = .modified // Default status, might need adjustment
    }

    // Full initializer for creating diffs with complete flexibility
    init(raw: String, header: String, extendedHeaderLines: [String], fromFileToFileLines: [String], chunks: [Chunk]) {
        self.raw = raw
        self.header = header
        self.extendedHeaderLines = extendedHeaderLines
        self.fromFileToFileLines = fromFileToFileLines
        self.chunks = chunks
        self.status = .modified // Default status, might need adjustment
    }

    func updateAll(stage: Bool) -> Self {
        guard !chunks.isEmpty else {
            var newSelf = self
            newSelf.stage = stage
            return newSelf
        }
        let newChunks = chunks.map { chunk in
            var newChunk = chunk
            newChunk.stage = stage
            return newChunk
        }
        var new = self
        new.chunks = newChunks
        return new
    }

    func stageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [stageString]
        }
        return chunks.map { $0.stageString }
    }

    func unstageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [unstageString]
        }
        return chunks.map { $0.unstageString }
    }

    // MARK: - Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileDiff, rhs: FileDiff) -> Bool {
        return lhs.id == rhs.id
    }
}
