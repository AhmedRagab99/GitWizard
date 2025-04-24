//
//  HistoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct HistoryView: View {
    @Bindable var viewModel: GitViewModel
    @State private var selectedCommit: Commit?
    @State private var isLoadingMore = false
    @State private var commits: [Commit] = []

    var body: some View {
        VStack(spacing: 0) {
            // Commit list
            List(commits) { commit in
                CommitRowView(
                    commit: commit,
                    isSelected: selectedCommit?.id == commit.id,
                    onSelect: {
                        selectedCommit = commit
                        viewModel.loadCommitDetails(commit)
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)

            // Commit details
            if let selectedCommit = selectedCommit {
                CommitDetailView(
                    commit: selectedCommit,
                    details: viewModel.commitDetails,
                    viewModel: viewModel
                )
            }
        }
        .task {
            // Initial load of commits
            commits = await viewModel.logStore.getCommits()
        }
    }
}
