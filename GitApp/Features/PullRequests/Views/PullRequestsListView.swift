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
            } else if let errorMessage = viewModel.errorMessage, viewModel.pullRequests.isEmpty {
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
                await viewModel.selectPullRequest(selectedPR)
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
//            viewModel.selectedPullRequest = nil
        }
        .sheet(isPresented: $isShowingCreatePRView) {
            CreatePullRequestView(viewModel: viewModel)
        }
        .task {
            if viewModel.pullRequests.isEmpty {
                await viewModel.loadPullRequests()
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
            .disabled(viewModel.isLoadingPullRequests)
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
            .disabled(viewModel.isLoadingPullRequests) // Could have other disabling logic
        }
    }

    private var listContentView: some View {
        List(selection: $viewModel.selectedPullRequest) {
            ForEach(viewModel.pullRequests) { pr in
                PullRequestRow(pullRequest: pr)
                    .tag(pr)
                    .task {
                        if pr.id == viewModel.pullRequests.last?.id && viewModel.canLoadMorePullRequests && !viewModel.isLoadingPullRequests {
                            await viewModel.loadPullRequests()
                        }
                    }
            }

            if viewModel.isLoadingPullRequests && !viewModel.pullRequests.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if !viewModel.canLoadMorePullRequests && !viewModel.pullRequests.isEmpty {
                 Text("No more pull requests.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .listStyle(.inset) // Or .plain for macOS
    }
}
