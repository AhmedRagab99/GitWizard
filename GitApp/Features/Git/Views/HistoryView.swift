//
//  HistoryView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct HistoryView: View {
     var viewModel: GitViewModel
    @State private var selectedCommit: Commit?
    @State private var isLoadingMore = false
    @State private var showBlameInfo: Bool = false
    @State private var searchText = ""
    @State private var searchType: CommitSearchType = .commitMessage
    @State private var showAdvancedSearch = false

    // Track visible commits to optimize memory usage
    @State private var visibleCommitIDs = Set<UUID>()

    // Filtered commits based on search criteria
    private var filteredCommits: [Commit] {
        guard !searchText.isEmpty else {
            return viewModel.logStore.commits
        }

        return viewModel.logStore.commits.filter { commit in
            switch searchType {
            case .commitMessage:
                return commit.message.localizedCaseInsensitiveContains(searchText)
            case .author:
                return commit.author.localizedCaseInsensitiveContains(searchText)
            case .sha:
                return commit.hash.localizedCaseInsensitiveContains(searchText)
            case .tagOrBranch:
                // This is a simplified implementation since we don't have branch/tag info here
                // You might want to implement a more sophisticated lookup
                let matchingTags = viewModel.tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                let matchingBranches = viewModel.branches.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

                return matchingTags.contains(where: { $0.commitHash == commit.hash }) ||
                       matchingBranches.contains(where: { $0.point == commit.hash })
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search controls
            VStack(spacing: 0) {
                if showAdvancedSearch {
                    HStack {
                        Picker("Search Type:", selection: $searchType) {
                            ForEach(CommitSearchType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 500)

                        Spacer()

                        // Blame toggle
                        Toggle(isOn: $showBlameInfo) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.text.rectangle")
                                Text("Show Blame")
                                    .font(.callout)
                            }
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                
                
                
                
                
            }
            .background(Color(.controlBackgroundColor))

            // Use LazyVStack within ScrollView for better memory management
            Card(
                title: "",
                backgroundColor: Color(.windowBackgroundColor),
                cornerRadius: 8,
                shadowRadius: 1,
                padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            ) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCommits) { commit in
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
//                            .id(commit.id)
                            .padding(.vertical, 1)
                            .background(Color.clear)
                            // Track visibility for memory optimization
                            .onFirstAppear {
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
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }

                        // Show empty state if no commits and not loading
                        if filteredCommits.isEmpty && !viewModel.isLoading {
                            EmptyListView(
                                title: searchText.isEmpty ? "No Commits Found" : "No Matching Commits",
                                message: searchText.isEmpty ?
                                    "There are no commits to display for this repository" :
                                    "No commits match your search criteria",
                                systemImage: searchText.isEmpty ? "text.badge.xmark" : "magnifyingglass"
                            )
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
            }

            // Commit details - only show when actually needed
            if let selectedCommit = selectedCommit {
                CommitDetailView(
                    commit: selectedCommit,
                    details: viewModel.commitDetails,
                    viewModel: viewModel,
                    showBlameInfo: showBlameInfo,
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
        // Cleanup resources when view disappears
        .onDisappear {
            selectedCommit = nil
            viewModel.commitDetails = nil
        }
    }
}

