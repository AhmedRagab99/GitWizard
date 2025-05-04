//
//  LogStore.swift
//  GitApp
//
//  Created by Ahmed Ragab on 21/04/2025.
//

import Foundation
import Observation


@Observable class LogStore {
    var number = 50 // Default page size
    var directory: URL?
    private var currentPage = 0
    private var hasMoreCommits = true
    var isLoading = false
    var isLoadingMore = false

    private var grep: [String] {
        searchTokens.filter { token in
            switch token.kind {
            case .grep, .grepAllMatch:
                return true
            case .g, .s, .author, .revisionRange:
                return false
            }
        }.map { $0.text }
    }

    private var grepAllMatch: Bool {
        searchTokens.contains { $0.kind == .grepAllMatch }
    }

    private var s: String {
        searchTokens.filter { $0.kind == .s }.map { $0.text }.first ?? ""
    }

    private var g: String {
        searchTokens.filter { $0.kind == .g }.map { $0.text }.first ?? ""
    }

    private var author: String {
        searchTokens.filter { $0.kind == .author }.map { $0.text }.first ?? ""
    }

    private var searchTokenRevisionRange: String {
        searchTokens.filter { $0.kind == .revisionRange }.map { $0.text }.first ?? ""
    }

    var searchTokens: [SearchToken] = []
    var commits: [Commit] = []
    var notCommitted: NotCommitted?
    var error: Error?

    func logs() -> [Log] {
        var logs = commits.map { Log.committed($0) }
        if let notCommitted, !notCommitted.isEmpty {
            logs.insert(.notCommitted, at: 0)
        }
        return logs
    }

    func refresh() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }

        do {
            isLoading = true
            currentPage = 0
            hasMoreCommits = true

            notCommitted = try await notCommited(directory: directory)

            guard searchTokenRevisionRange.isEmpty else {
                commits = try await loadCommitsWithSearchTokenRevisionRange(directory: directory, revisionRange: searchTokenRevisionRange)
                return
            }

            defer { isLoading = false }
            commits = try await Process.output(GitLog(
                directory: directory,
                number: number,
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g,
                author: author,
                skip: currentPage * number
            ))

            hasMoreCommits = commits.count == number
        } catch {
            self.error = error
        }
    }

    private func loadCommitsWithSearchTokenRevisionRange(directory: URL, revisionRange: String) async throws -> [Commit] {
        try await Process.output(GitLog(
            directory: directory,
            revisionRange: revisionRange,
            grep: grep,
            grepAllMatch: grepAllMatch,
            s: s,
            g: g,
            author: author,
            skip: 0
        ))
    }

    func loadMore() async {
        guard let directory = directory,
              !isLoadingMore,
              hasMoreCommits else { return }

        do {
            isLoadingMore = true
            currentPage += 1
            defer { isLoadingMore = false }

            let newCommits = try await Process.output(GitLog(
                directory: directory,
                number: number,
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g,
                author: author,
                skip: currentPage * number
            ))

            commits.append(contentsOf: newCommits)
            hasMoreCommits = newCommits.count == number
        } catch {
            self.error = error
        }
    }

    func removeAll() {
        commits = []
        notCommitted = nil
        currentPage = 0
        hasMoreCommits = true
    }

    func logViewTask(_ log: Log) async {
        switch log {
        case .notCommitted:
            return
        case .committed(let commit):
            if commit == commits.last {
                await loadMore()
            }
        }
    }

    private func notCommited(directory: URL) async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiff(directory: directory, cached: true))
        let status = try await Process.output(GitStatus(directory: directory))
        return NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }
}
