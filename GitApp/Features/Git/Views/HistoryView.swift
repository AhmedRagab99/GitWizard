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
    @GestureState private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Commit list
            List {
                ForEach(viewModel.logStore.commits) { commit in
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
                    .task(priority: .background) {
                        // Load more when we reach the last item
                        if commit == viewModel.logStore.commits.last && !viewModel.logStore.isLoadingMore {
                            Task {
                                await viewModel.logStore.loadMore()
                            }
                        }
                    }
                }
                
               
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.logStore.refresh()
            }
            
            // Commit details with close button and drag gesture
            if let selectedCommit = selectedCommit {
                
                CommitDetailView(
                    commit: selectedCommit,
                    details: viewModel.commitDetails,
                    viewModel: viewModel
                )
                .offset(y: dragOffset.height)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation {
                                    self.selectedCommit = nil
                                }
                            }
                        }
                )
                .transition(.move(edge: .bottom))
            }
            
        }
    }
}
