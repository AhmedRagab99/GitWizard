import SwiftUI

struct PullRequestsListView: View {
    @Bindable var viewModel: PullRequestViewModel
    @State private var isShowingCreatePRView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // New unified header using Card
            Card {
                HStack(spacing: 12) {
                    Picker("Filter", selection: $viewModel.currentFilterState) {
                        ForEach(PullRequestState.allCases) { state in
                            Text(state.displayName).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(minWidth: 200, idealWidth: 250)

                    Spacer()

                    Button {
                        Task {
                            await viewModel.loadPullRequests(refresh: true)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Pull Requests")
                    .disabled(viewModel.isLoadingPullRequests && viewModel.pullRequests.isEmpty)
                    .buttonStyle(.borderless)
                    .padding(.leading)

                    Button {
                        isShowingCreatePRView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                        Text("New Pull Request")
                    }
                    .help("Create New Pull Request")
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)

            // Content Area (Progress, Error, or List)
            if viewModel.isLoadingPullRequests && viewModel.pullRequests.isEmpty {
                ProgressView("Loading Pull Requests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.pullRequestListError, viewModel.pullRequests.isEmpty {
                EmptyListView(
                    title: "Error Loading Pull Requests",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    action: {
                        Task {
                            await viewModel.loadPullRequests(refresh: true)
                        }
                    },
                    actionTitle: "Retry"
                )
            } else if viewModel.pullRequests.isEmpty {
                EmptyListView(
                    title: "No Pull Requests",
                    message: "No pull requests found matching the current filter.",
                    systemImage: "doc.text.magnifyingglass"
                )
            } else {
                Card {
                    listContentView
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .onChange(of: viewModel.selectedPullRequest) { oldValue, newValue in
            guard let selectedPR = newValue else { return }
                    Task {
                let windowId = "pull-request-detail-\(selectedPR.id)-\(selectedPR.number)"
                let windowTitle = "PR #\(selectedPR.number): \(selectedPR.title)"
                openNewWindow(
                    with: PullRequestDetailView(pullRequest: selectedPR, viewModel: viewModel),
                    id: windowId,
                    title: windowTitle,
                    width: 800,
                    height: 600
                )
                }
            // viewModel.selectedPullRequest = nil // Decide if PR should be deselected after opening new window
        }
        .sheet(isPresented: $isShowingCreatePRView) {
            CreatePullRequestView(viewModel: viewModel)
        }
        .task {
            if viewModel.pullRequests.isEmpty && viewModel.pullRequestListError == nil {
                await viewModel.loadPullRequests(refresh: true) // Initial load
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var listContentView: some View {
        List(selection: $viewModel.selectedPullRequest) {
            ForEach(viewModel.pullRequests) { pr in
                PullRequestRow(pullRequest: pr)
                    .tag(pr)
                    .onAppear {
                        if pr.id == viewModel.pullRequests.last?.id && viewModel.canLoadMorePullRequests && !viewModel.isLoadingPullRequests {
                            Task {
                                await viewModel.loadPullRequests(refresh: false) // Correctly call for pagination
                            }
                        }
                    }
            }

            // Loading indicator for pagination
            if viewModel.isLoadingPullRequests && !viewModel.pullRequests.isEmpty {
                HStack {
                    Spacer()
                    ProgressView() // Simpler progress view for loading more
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .frame(height: 50) // Give it some space
            }

            // Optional: Message when all items are loaded
            if !viewModel.canLoadMorePullRequests && !viewModel.pullRequests.isEmpty && viewModel.pullRequestListError == nil {
                 Text("You've reached the end of the list.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.inset) // Or .plain for macOS
    }
}
