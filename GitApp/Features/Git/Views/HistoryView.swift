//
//  HistoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct HistoryView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var selectedCommit: Commit?

    var body: some View {
        VStack(spacing: 0) {
            // Commit list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.logStore.commits) { commit in
                        CommitRowView(
                            commit: commit,
                            isSelected: selectedCommit?.id == commit.id,
                            onSelect: {
                                selectedCommit = commit
                                viewModel.loadCommitDetails(commit)
                            }
                        )
                    }
                }
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
