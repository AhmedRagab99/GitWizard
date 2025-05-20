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

    // Track visible commits to optimize memory usage
    @State private var visibleCommitIDs = Set<UUID>()

    var body: some View {
        VStack(spacing: 0) {
            // Use LazyVStack within ScrollView for better memory management
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.logStore.commits) { commit in
                        CommitRowView(
                            commit: commit,
                            isSelected: selectedCommit?.id == commit.id,
                            onSelect: {
                                // Only load details if this is a new selection
                                if selectedCommit?.id != commit.id {
                                    selectedCommit = commit
                                    viewModel.loadCommitDetails(commit)
                                }
                            }
                        )
                        .id(commit.id)
                        .padding(.vertical, 1)
                        .background(Color.clear)
                        // Track visibility for memory optimization
                        .onAppear {
                            visibleCommitIDs.insert(commit.id)

                            // Trigger pagination when reaching end
                            if commit == viewModel.logStore.commits.last && !viewModel.logStore.isLoadingMore && !isLoadingMore {
                                isLoadingMore = true
                                Task {
                                    await viewModel.logStore.loadMore()
                                    isLoadingMore = false
                                }
                            }
                        }
                        .onDisappear {
                            visibleCommitIDs.remove(commit.id)
                        }
                        Divider()
                    }

                    // Loading indicator
                    if isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .refreshable {
                // Clear selections on refresh to avoid stale references
                selectedCommit = nil
                viewModel.commitDetails = nil
                await viewModel.logStore.refresh()
            }

            // Commit details - only show when actually needed
            if let selectedCommit = selectedCommit {
                CommitDetailView(
                    commit: selectedCommit,
                    details: viewModel.commitDetails,
                    viewModel: viewModel,
                    onClose: {
                        withAnimation(.easeInOut) {
                            self.selectedCommit = nil
                            // Clear commit details to free memory
                            viewModel.commitDetails = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .loading(viewModel.isLoading)
        .errorAlert(viewModel.errorMessage)
        // Cleanup resources when view disappears
        .onDisappear {
            selectedCommit = nil
            viewModel.commitDetails = nil
        }
    }
}
