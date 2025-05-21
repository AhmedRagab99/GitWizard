import SwiftUI


struct PullRequestDetailView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Bindable var gitViewModel: GitViewModel

    let pullRequest: PullRequest
    @State private var selectedTab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case files = "Changes"
        case comments = "Comments"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .files: return "doc.text"
            case .comments: return "text.bubble"
            }
        }
    }

    // Using computed property to get the current full PR data
    private var currentPR: PullRequest {
        // Use the detailed data if available, otherwise use the passed-in PR
        viewModel.selectedPullRequest ?? pullRequest
    }

    // Track expanded file state
    @State private var expandedFileId: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                pullRequestHeader
                    .padding()
                    .background(Color(.controlBackgroundColor))

                // Tab selector
                tabSelector
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Tab content
                selectedTabContent
                    .padding(.top, 16)
            }
        }
        .navigationTitle("PR #\(pullRequest.number)")
        .onAppear {
            Task {
                await viewModel.loadPullRequestDetails(for: pullRequest)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading PR details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }

    private var pullRequestHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and state badge
            HStack(alignment: .center) {
                Text(currentPR.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                prStateBadge
            }

            // Meta information
            VStack(alignment: .leading, spacing: 8) {
                // Author and dates
                HStack {
                    Label(currentPR.author, systemImage: "person")
                        .font(.subheadline)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("Created \(formatDate(currentPR.createdAt))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if currentPR.updatedAt != currentPR.createdAt {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text("Updated \(formatDate(currentPR.updatedAt))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Branches
                HStack(spacing: 12) {
                    Label {
                        Text(currentPR.headBranch)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(.blue)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    Label {
                        Text(currentPR.baseBranch)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(.green)
                    }
                }

                // Changes summary
                let fileCount = currentPR.files.count
                if fileCount > 0 {
                    HStack(spacing: 16) {
                        Label("\(fileCount) files", systemImage: "doc")
                            .font(.subheadline)

                        Label {
                            Text("\(currentPR.files.reduce(0) { $0 + $1.additions })")
                                .foregroundStyle(.green)
                        } icon: {
                            Image(systemName: "plus")
                                .foregroundStyle(.green)
                        }
                        .font(.subheadline)

                        Label {
                            Text("\(currentPR.files.reduce(0) { $0 + $1.deletions })")
                                .foregroundStyle(.red)
                        } icon: {
                            Image(systemName: "minus")
                                .foregroundStyle(.red)
                        }
                        .font(.subheadline)
                    }
                }
            }

            // Description
            if !currentPR.description.isEmpty {
                Text(currentPR.description)
                    .font(.body)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var prStateBadge: some View {
        let stateColor: Color = {
            switch currentPR.state {
            case .open: return .green
            case .closed: return .red
            case .merged: return .purple
            }
        }()

        return HStack(spacing: 6) {
            Image(systemName: currentPR.state.icon)
            Text(currentPR.state.rawValue.capitalized)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(stateColor)
        .clipShape(Capsule())
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                tabButton(tab)
            }

            Spacer()
        }
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: tab.icon)
                    Text(tab.rawValue)
                }
                .font(.subheadline)
                .fontWeight(selectedTab == tab ? .semibold : .regular)
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)

                // Active indicator
                Rectangle()
                    .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .files:
            filesContent
        case .comments:
            commentsContent
        }
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let pr = viewModel.selectedPullRequest, !pr.description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    Text(pr.description)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }

            // Review status
            VStack(alignment: .leading, spacing: 8) {
                Text("Review Status")
                    .font(.headline)

                HStack(spacing: 12) {
                    Image(systemName: pullRequest.reviewStatus.icon)
                        .foregroundStyle(reviewStatusColor(pullRequest.reviewStatus))

                    Text(pullRequest.reviewStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .foregroundStyle(reviewStatusColor(pullRequest.reviewStatus))
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal)

            // Changed files summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Files Changed")
                    .font(.headline)

                HStack(spacing: 20) {
                    ForEach(fileStatusStats(), id: \.0) { status, count in
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: statusIconName(status))
                                    .foregroundStyle(statusColor(status))
                                Text("\(count)")
                            }
                            .font(.system(size: 16, weight: .medium))

                            Text(status.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minWidth: 80)
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var filesContent: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            if currentPR.files.isEmpty {
                Text("No file changes available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Text("Changed Files (\(currentPR.files.count))")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(currentPR.files) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        // File header section will be handled by FileChangeSection
                        FileChangeSection(
                            fileDiff: file.diff,
                            viewModel: gitViewModel,
                            isExpanded: file.diff.id == expandedFileId
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                if expandedFileId == file.diff.id {
                                    expandedFileId = nil
                                } else {
                                    expandedFileId = file.diff.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 20) // Add some bottom padding
    }

    private var commentsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if currentPR.comments.isEmpty {
                Text("No comments")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(currentPR.comments, id: \.id) { comment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(comment.author)
                                .font(.headline)

                            Text("commented \(formatDate(comment.createdAt))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if let path = comment.path, let line = comment.line {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.caption)

                                    Text("\(path.components(separatedBy: "/").last ?? path):\(line)")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }

                        Text(comment.content)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func fileStatusStats() -> [(FileStatus, Int)] {
        var counts: [FileStatus: Int] = [:]

        for file in currentPR.files {
            counts[file.status, default: 0] += 1
        }

        return counts.filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func statusIconName(_ status: FileStatus) -> String {
        status.icon
    }

    private func statusColor(_ status: FileStatus) -> Color {
        status.color
    }

    private func reviewStatusColor(_ status: ReviewStatus) -> Color {
        switch status {
        case .approved: return .green
        case .changesRequested: return .red
        case .pending: return .orange
        }
    }

    // Helper methods for simplifying the complex expressions
    private func lineColor(_ line: Line) -> Color {
        switch line.kind {
        case .added: return .green
        case .removed: return .red
        default: return .secondary
        }
    }

    private func lineBackground(_ line: Line) -> Color {
        switch line.kind {
        case .added: return SyntaxTheme.added
        case .removed: return SyntaxTheme.removed
        default: return SyntaxTheme.normalText
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PullRequestDetailView(
            viewModel: PullRequestViewModel(), gitViewModel: GitViewModel(),
            pullRequest: PullRequest(
                id: "1",
                number: 123,
                title: "Add new feature",
                description: "This PR adds an exciting new feature to the app",
                author: "johndoe",
                state: .open,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-3600),
                baseBranch: "main",
                headBranch: "feature/new-feature",
                files: [],
                comments: [],
                reviewStatus: .pending
            )
        )
    }
}
