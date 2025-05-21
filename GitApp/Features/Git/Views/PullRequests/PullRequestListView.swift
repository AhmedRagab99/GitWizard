import SwiftUI

struct PullRequestListView: View {
    @Bindable var viewModel: PullRequestViewModel
    @State private var showSortOptions = false
    @State private var showFilterOptions = false
    var showContentLoading: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            searchAndFilterBar
                .padding()
                .background(Color(.controlBackgroundColor))
                .animation(.easeInOut, value: showFilterOptions)

            // Status filter tabs
            stateFilterTabs
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(.controlBackgroundColor))

            // Pull request list
            if viewModel.isLoading && showContentLoading {
                ProgressView("Loading pull requests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredPullRequests.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                pullRequestList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            // Error toast
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPullRequests()
            }
        }
    }

    // MARK: - Search and Filter Bar

    private var searchAndFilterBar: some View {
        HStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search pull requests", text: $viewModel.searchText)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Sort button
            Menu {
                ForEach(PRSortOption.allCases) { option in
                    Button(action: {
                        viewModel.applySorting(by: option, direction: viewModel.sortDirection)
                    }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.sortBy == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                ForEach(SortDirection.allCases) { direction in
                    Button(action: {
                        viewModel.applySorting(by: viewModel.sortBy, direction: direction)
                    }) {
                        HStack {
                            Text(direction.displayName)
                            Image(systemName: direction.icon)
                            if viewModel.sortDirection == direction {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .symbolVariant(showSortOptions ? .fill : .none)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)

            // Refresh button
            Button(action: {
                Task {
                    await viewModel.loadPullRequests()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - State Filter Tabs

    private var stateFilterTabs: some View {
        HStack(spacing: 16) {
            stateFilterButton(title: "Open", state: .open, count: viewModel.stateCounters[.open] ?? 0)
            stateFilterButton(title: "Closed", state: .closed, count: viewModel.stateCounters[.closed] ?? 0)
            stateFilterButton(title: "Merged", state: .merged, count: viewModel.stateCounters[.merged] ?? 0)
            stateFilterButton(title: "All", state: nil, count: viewModel.pullRequests.count)

            Spacer()
        }
    }

    private func stateFilterButton(title: String, state: PullRequestState?, count: Int) -> some View {
        Button(action: {
            withAnimation {
                viewModel.applyStateFilter(state)
            }
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .fontWeight(viewModel.filterState == state ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Indicator for selected tab
                Rectangle()
                    .fill(viewModel.filterState == state ? Color.accentColor : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pull Request List

    private var pullRequestList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.filteredPullRequests) { pullRequest in
                    NavigationLink(value: pullRequest) {
                        PullRequestRow(pullRequest: pullRequest)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.controlBackgroundColor))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.automatic)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.pull")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolVariant(.circle)

            Text("No pull requests found")
                .font(.headline)

            if let filterState = viewModel.filterState {
                Text("No \(filterState.rawValue) pull requests match your filters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !viewModel.searchText.isEmpty {
                Text("Try changing your search terms")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Refresh") {
                Task {
                    await viewModel.loadPullRequests()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Pull Request Row

struct PullRequestRow: View {
    let pullRequest: PullRequest

    private var stateColor: Color {
        switch pullRequest.state {
        case .open: return .green
        case .closed: return .red
        case .merged: return .purple
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status icon
            Image(systemName: pullRequest.state.icon)
                .foregroundStyle(stateColor)
                .font(.system(size: 16))
                .padding(4)
                .background(
                    Circle()
                        .strokeBorder(stateColor, lineWidth: 1)
                )
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                // Title and number
                HStack(alignment: .firstTextBaseline) {
                    Text(pullRequest.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text("#\(pullRequest.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Author and date
                HStack {
                    Text("by \(pullRequest.author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(relativeDateString(for: pullRequest.updatedAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Branches
                HStack {
                    Label(pullRequest.headBranch, systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .padding(4)
                        .background(Color(.quaternaryLabelColor).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(pullRequest.baseBranch, systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .padding(4)
                        .background(Color(.quaternaryLabelColor).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Spacer()

            // Review status badge
             let reviewStatus = pullRequest.reviewStatus
                HStack(spacing: 4) {
                    Image(systemName: reviewStatus.icon)
                        .font(.caption)
                    Text(reviewStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                }
                .padding(4)
                .foregroundStyle(.white)
                .background(reviewStatusColor(for: reviewStatus))
                .clipShape(RoundedRectangle(cornerRadius: 4))

        }
    }

    private func reviewStatusColor(for status: ReviewStatus) -> Color {
        switch status {
        case .approved: return .green
        case .changesRequested: return .red
        case .pending: return .orange
        }
    }

    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PullRequestListView(viewModel: PullRequestViewModel())
            .navigationTitle("Pull Requests")
    }
}
