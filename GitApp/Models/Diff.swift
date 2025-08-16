//
//  Diff.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

class Diff: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(raw)
    }
    
    static func == (lhs: Diff, rhs: Diff) -> Bool {
        lhs.raw == rhs.raw
    }
    
    var fileDiffs: [FileDiff]
    var raw: String

    init(raw: String) throws {
        self.raw = raw
        guard !raw.isEmpty else {
            fileDiffs = []
            return
        }
        fileDiffs = try ("\n" + raw).split(separator: "\ndiff").map { fileDiffRaw in
            let fileDiff = try FileDiff(raw: String("diff" + fileDiffRaw))
            return fileDiff
        }
    }

    func updateAll(stage: Bool) -> Self {
        let newFileDiffs = fileDiffs.map { fileDiff in
            fileDiff.updateAll(stage: stage)
        }
        var new = self
        new.fileDiffs = newFileDiffs
        return new
    }

    func updateFileDiffStage(_ fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex else { return self }
        var new = self
        new.fileDiffs[fileDiffIndex].stage = stage
        return new
    }

    func updateChunkStage(_ chunk: Chunk, in fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex else { return self }
        let chunkIndex = fileDiffs[fileDiffIndex].chunks.firstIndex { $0.id == chunk.id }
        guard let chunkIndex else { return self }
        var new = self
        var newChunk = chunk
        newChunk.stage = stage
        new.fileDiffs[fileDiffIndex].chunks[chunkIndex] = newChunk
        return new
    }

    func stageStrings() -> [String] {
        Array(fileDiffs.map { $0.stageStrings() }.joined())
    }

    func unstageStrings() -> [String] {
        Array(fileDiffs.map { $0.unstageStrings() }.joined())
    }
}
