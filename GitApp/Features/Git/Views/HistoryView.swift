//
//  HistoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation
import Observation

struct HistoryView: View {
    @Bindable var viewModel: GitViewModel
    @State private var selectedCommit: Commit?
    @State private var isLoadingMore = false
    @State private var hasReachedEnd = false

    var body: some View {
        VStack(spacing: 0) {
            // Commit list
            List {
                ForEach(viewModel.getCommits()) { commit in
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
                    .task {
                        await viewModel.loadMoreCommits(commit: commit)

            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refreshCommits()
            }

            // Commit details
            if let selectedCommit = selectedCommit {
                CommitDetailView(
                    commit: selectedCommit,
                    details: viewModel.commitDetails,
                    viewModel: viewModel
                )
            }
        }
    }
}

