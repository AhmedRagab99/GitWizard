import SwiftUI

struct PullRequestsListView: View {
    @Bindable var viewModel: PullRequestViewModel
    @State private var isShowingCreatePRView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // New unified header
            newHeaderView
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar) // A slight background to distinguish the header area

            Divider() // Visually separate header from list content

            // Content Area (Progress, Error, or List)
            if viewModel.isLoadingPullRequests && viewModel.pullRequests.isEmpty {
                ProgressView("Loading Pull Requests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.pullRequestListError, viewModel.pullRequests.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error Loading Pull Requests")
                        .font(.title2)
                    Text(errorMessage)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Button {
                        Task {
                            await viewModel.loadPullRequests(refresh: true)
                        }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pullRequests.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Pull Requests")
                        .font(.title2)
                    Text("No pull requests found matching the current filter.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                     // Optionally, a Retry button here as well if applicable
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                listContentView
            }
        }
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

    // Redesigned headerView
    private var newHeaderView: some View {
        HStack(spacing: 12) {
            Picker("Filter", selection: $viewModel.currentFilterState) {
                ForEach(PullRequestState.allCases) { state in
                    Text(state.displayName).tag(state)
                }
            }
            .pickerStyle(.segmented)
            // .labelsHidden() // Keep labels for clarity or style as preferred
            .frame(minWidth: 200, idealWidth: 250) // Give picker some defined space

            Spacer()

            Button {
                Task {
                    await viewModel.loadPullRequests(refresh: true)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Pull Requests")
            .disabled(viewModel.isLoadingPullRequests && viewModel.pullRequests.isEmpty) // Disable only if initial load is happening
            .buttonStyle(.borderless) // More subtle button style for header icons
            .padding(.leading)

            Button {
                isShowingCreatePRView = true
            } label: {
                Image(systemName: "plus.circle.fill")
                Text("New") // Shortened text for header button
            }
            .help("Create New Pull Request")
            // .buttonStyle(.bordered) // or .borderless, choose based on desired emphasis
        }
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
