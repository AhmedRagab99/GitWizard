//
//  HistoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: GitViewModel

    private func groupCommitsByMonth(_ commits: [Commit]) -> [(month: Date, commits: [Commit])] {
        let grouped = Dictionary(grouping: commits) { commit in
            Calendar.current.startOfMonth(for: commit.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (month: $0.key, commits: $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupCommitsByMonth(viewModel.branchCommits), id: \.month) { group in
                    Section(header: MonthHeaderView(date: group.month)) {
                        ForEach(Array(zip(group.commits.indices, group.commits)), id: \.0) { index, commit in
                            CommitRowView(
                                commit: commit,
                                previousCommit: index > 0 ? group.commits[index - 1] : nil,
                                nextCommit: index < group.commits.count - 1 ? group.commits[index + 1] : nil
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedCommit = commit
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.windowBackgroundColor))
    }
}
