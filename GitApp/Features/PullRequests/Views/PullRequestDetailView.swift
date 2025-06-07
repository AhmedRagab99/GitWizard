import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    @Bindable var viewModel: PullRequestViewModel

    @State private var selectedTab: Int = 0 // 0: Description, 1: Comments, 2: Code Comments, 3: Files, 4: Reviews
    @State private var isShowingMergeSheet = false
    @State private var isShowingRequestChangesSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            prInfoHeader
                .padding()
                .background(Material.bar) // Gives a slightly elevated, modern header look

            Picker("Details", selection: $selectedTab) {
                Label("Description", systemImage: "doc.text").tag(0)
                Label("Comments (\(viewModel.comments.count))", systemImage: "bubble.left.and.bubble.right").tag(1)
                Label("Code Comments (\(viewModel.reviewComments.count))", systemImage: "text.bubble").tag(2)
                Label("Files (\(viewModel.files.count))", systemImage: "doc.on.doc").tag(3)
                Label("Reviews (\(viewModel.reviews.count))", systemImage: "person.crop.circle.badge.checkmark").tag(4)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            // Content based on selection using a switch statement
            // The ZStack with alignment helps ensure that the content view takes up available space,
            // similar to how TabView behaves, preventing the actionButtonsView from jumping up.
            ZStack(alignment: .topLeading) {
                switch selectedTab {
                case 0:
                    descriptionView
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it expands
                case 1:
                    commentsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it expands
                case 2:
                    reviewCommentsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case 3:
                    filesView
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it expands
                case 4:
                    reviewsView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make ZStack expand

            Divider()

            actionButtonsView
                .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor)) // Ensures a solid background
        // Trigger initial load of details if not already loaded (e.g. if view appears standalone)
        // However, `selectPullRequest` in the list view is the primary trigger.
        // This .task might be redundant if the typical flow always involves `selectPullRequest`.
        // Consider if selectedPullRequest is set *before* this view appears without `selectPullRequest` being called.
        .task(id: viewModel.selectedPullRequest?.id) { // Re-run if selected PR changes
            if viewModel.selectedPullRequest != nil && viewModel.comments.isEmpty && viewModel.reviewComments.isEmpty && viewModel.files.isEmpty && !viewModel.isLoadingInitialDetails {
                 // This ensures that if the view is somehow presented with a PR but details weren't loaded,
                 // they get loaded. This is a safety net.
                await viewModel.selectPullRequest(pullRequest) // Pass the local pullRequest
            }
        }
        .sheet(isPresented: $isShowingMergeSheet) {
            MergePullRequestView(viewModel: viewModel, isPresented: $isShowingMergeSheet)
        }
        .sheet(isPresented: $isShowingRequestChangesSheet) {
            RequestChangesView(viewModel: viewModel, isPresented: $isShowingRequestChangesSheet)
        }
    }

    private var prInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("#\(pullRequest.number) \(pullRequest.title)")
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(2)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                statusBadge(for: pullRequest.prState, merged: pullRequest.mergedAt != nil)
                Label{
                    Text("by \(pullRequest.user.login)")
                } icon: {
                     Image(systemName: "person.fill")
                }
                Label {
                    Text("Opened \(pullRequest.createdAt, style: .relative) ago")
                } icon: {
                     Image(systemName: "clock.arrow.circlepath")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let mergedAt = pullRequest.mergedAt {
                Label {
                    Text("Merged \(mergedAt, style: .date) at \(mergedAt, style: .time)")
                } icon: {
                    Image(systemName: "arrow.triangle.merge")
                }
                .font(.caption).foregroundColor(.purple)
            } else if let closedAt = pullRequest.closedAt {
                Label {
                    Text("Closed \(closedAt, style: .date) at \(closedAt, style: .time)")
                } icon: {
                     Image(systemName: "xmark.octagon.fill")
                }
                .font(.caption).foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for state: PullRequestState, merged: Bool) -> some View {
        let statusInfo = pullRequest.statusInfo
        Text(statusInfo.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(statusInfo.color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var descriptionView: some View {
        if viewModel.isLoadingInitialDetails && (pullRequest.body == nil || pullRequest.body!.isEmpty) {
            ProgressView("Loading Description...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let body = pullRequest.body, !body.isEmpty {
            ScrollView {
                Text(body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        } else {
            CenteredContentMessage(systemImage: "text.alignleft", message: "No description provided.")
        }
    }

    @ViewBuilder
    private var commentsView: some View {
        if viewModel.isLoadingInitialDetails && viewModel.comments.isEmpty && viewModel.commentsError == nil {
            ProgressView("Loading Comments...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.commentsError, viewModel.comments.isEmpty {
             CenteredContentMessage(systemImage: "exclamationmark.triangle.fill", title: "Error Loading Comments", message: errorMessage)
        } else if viewModel.comments.isEmpty && !viewModel.isLoadingMoreComments && !viewModel.isLoadingInitialDetails {
            CenteredContentMessage(systemImage: "bubble.middle.bottom.fill", message: "No discussion comments yet.")
        } else {
            List {
                ForEach(viewModel.comments) { comment in
                    PullRequestCommentView(comment: comment)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .onAppear {
                            if comment.id == viewModel.comments.last?.id && viewModel.canLoadMoreComments && !viewModel.isLoadingMoreComments {
                                Task {
                                    await viewModel.loadComments(refresh: false)
                                }
                            }
                        }
                }
                if viewModel.isLoadingMoreComments {
                    ProgressView("Loading more comments...")
                        .frame(maxWidth: .infinity).padding().listRowSeparator(.hidden)
                }
                if !viewModel.canLoadMoreComments && !viewModel.comments.isEmpty && viewModel.commentsError == nil {
                    Text("No more comments.").font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).padding().listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
             // Add pull to refresh if desired for this specific list
        }
    }

    @ViewBuilder
    private var reviewCommentsView: some View {
        if viewModel.isLoadingInitialDetails && viewModel.reviewComments.isEmpty && viewModel.reviewCommentsError == nil {
            ProgressView("Loading Code Comments...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.reviewCommentsError, viewModel.reviewComments.isEmpty {
             CenteredContentMessage(systemImage: "exclamationmark.triangle.fill", title: "Error Loading Code Comments", message: errorMessage)
        } else if viewModel.reviewComments.isEmpty && !viewModel.isLoadingMoreReviewComments && !viewModel.isLoadingInitialDetails {
            CenteredContentMessage(systemImage: "text.bubble.fill", message: "No code comments on this pull request.")
        } else {
            List {
                ForEach(viewModel.reviewComments) { comment in
                    PullRequestCommentView(comment: comment)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .onAppear {
                            if comment.id == viewModel.reviewComments.last?.id && viewModel.canLoadMoreReviewComments && !viewModel.isLoadingMoreReviewComments {
                                Task {
                                    await viewModel.loadReviewComments(refresh: false)
                                }
                            }
                        }
                }
                if viewModel.isLoadingMoreReviewComments {
                    ProgressView("Loading more code comments...")
                        .frame(maxWidth: .infinity).padding().listRowSeparator(.hidden)
                }
                 if !viewModel.canLoadMoreReviewComments && !viewModel.reviewComments.isEmpty && viewModel.reviewCommentsError == nil {
                    Text("No more code comments.").font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).padding().listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var filesView: some View {
        if viewModel.isLoadingInitialDetails && viewModel.files.isEmpty && viewModel.filesError == nil {
            ProgressView("Loading Files...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.filesError, viewModel.files.isEmpty {
            CenteredContentMessage(systemImage: "exclamationmark.triangle.fill", title: "Error Loading Files", message: errorMessage)
        } else if viewModel.files.isEmpty && !viewModel.isLoadingMoreFiles && !viewModel.isLoadingInitialDetails {
            CenteredContentMessage(systemImage: "doc.on.doc.fill", message: "No files changed in this pull request.")
        } else {
            List {
                ForEach(viewModel.files) { file in
                    PullRequestFileView(file: file, viewModel: viewModel, prCommitId: pullRequest.id.description)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .onAppear {
                            if file.id == viewModel.files.last?.id && viewModel.canLoadMoreFiles && !viewModel.isLoadingMoreFiles {
                                Task {
                                    await viewModel.loadFiles(refresh: false)
                                }
                            }
                        }
                }
                if viewModel.isLoadingMoreFiles {
                    ProgressView("Loading more files...")
                        .frame(maxWidth: .infinity).padding().listRowSeparator(.hidden)
                }
                if !viewModel.canLoadMoreFiles && !viewModel.files.isEmpty && viewModel.filesError == nil {
                    Text("No more files.").font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).padding().listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var reviewsView: some View {
        if viewModel.isLoadingReviews && viewModel.reviews.isEmpty {
            ProgressView("Loading Reviews...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.reviewsError, viewModel.reviews.isEmpty {
             CenteredContentMessage(systemImage: "exclamationmark.triangle.fill", title: "Error Loading Reviews", message: errorMessage)
        } else if viewModel.reviews.isEmpty && !viewModel.isLoadingReviews {
            CenteredContentMessage(systemImage: "person.crop.circle.badge.checkmark", message: "No reviews have been submitted.")
        } else {
            List {
                ForEach(viewModel.reviews) { review in
                    PullRequestReviewView(review: review)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
        }
    }

    private var actionButtonsView: some View {
        HStack {
            Spacer()

            Button(action: {
                isShowingRequestChangesSheet = true
            }) {
                Label("Request Changes", systemImage: "xmark.circle.fill")
            }
            .disabled(pullRequest.prState != .open)

            Button(action: {
                Task {
                    await viewModel.approvePullRequest()
                }
            }) {
                Label("Approve", systemImage: "checkmark.circle.fill")
            }
            .disabled(pullRequest.prState != .open)

            Button(action: {
                viewModel.prepareMergeDetails()
                isShowingMergeSheet = true
            }) {
                Label("Merge Pull Request", systemImage: "arrow.triangle.merge")
            }
            .buttonStyle(.borderedProminent)
            .disabled(pullRequest.prState != .open)
        }
        .padding(.horizontal)
    }
}

// Helper View for centered messages (like "No description")
struct CenteredContentMessage: View {
    let systemImage: String
    var title: String? = nil // Optional title
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            if let title = title, !title.isEmpty {
                 Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Extension to PullRequest to get status display info (should be in PullRequest.swift)
extension PullRequest {
    struct StatusDisplayInfo {
        let displayName: String
        let color: Color
        let systemImage: String
    }

    var statusInfo: StatusDisplayInfo {
        if mergedAt != nil {
            return StatusDisplayInfo(displayName: "Merged", color: .purple, systemImage: "arrow.triangle.merge")
        } else if state == "closed" {
            return StatusDisplayInfo(displayName: "Closed", color: .red, systemImage: "xmark.octagon.fill")
        } else {
            return StatusDisplayInfo(displayName: "Open", color: .green, systemImage: "checkmark.circle.fill")
        }
    }
}
