import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    @Bindable var viewModel: PullRequestViewModel // Ensure @Bindable if viewModel's properties are changed by this view directly

    @State private var selectedTab: Int = 0 // 0: Description, 1: Comments, 2: Files

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            prInfoHeader
                .padding()
                .background(Material.bar) // Gives a slightly elevated, modern header look

            Picker("Details", selection: $selectedTab) {
                Label("Description", systemImage: "doc.text").tag(0)
                Label("Comments (\(viewModel.comments.count))", systemImage: "bubble.left.and.bubble.right").tag(1)
                Label("Files (\(viewModel.files.count))", systemImage: "doc.on.doc").tag(2)
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
                    filesView
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it expands
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make ZStack expand

            actionButtonsView
                .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor)) // Ensures a solid background
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
        // Ensure ScrollView is only used if content might actually overflow.
        // If body is typically short, ScrollView might not be needed, or conditional.
        Group {
            if let body = pullRequest.body, !body.isEmpty {
                ScrollView {
                    Text(body) // Consider a Markdown renderer for richer text
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            } else {
                CenteredContentMessage(systemImage: "text.alignleft", message: "No description provided.")
            }
        }
    }

    @ViewBuilder
    private var commentsView: some View {
        Group {
            if viewModel.isLoadingDetails && viewModel.comments.isEmpty {
                ProgressView("Loading Comments...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.comments.isEmpty {
                CenteredContentMessage(systemImage: "bubble.middle.bottom.fill", message: "No comments yet.")
            } else {
                List(viewModel.comments) { comment in
                    PullRequestCommentView(comment: comment)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain) // Or .inset for a slightly different look
            }
        }
    }

    @ViewBuilder
    private var filesView: some View {
        if viewModel.isLoadingDetails && viewModel.files.isEmpty {
            ProgressView("Loading Files...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.files.isEmpty {
            CenteredContentMessage(systemImage: "doc.on.doc.fill",
                                   message: "No files changed in this pull request.")
        } else {
            List(viewModel.files) { file in
                PullRequestFileView(file: file)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)) // Adjusted vertical
            }
            .listStyle(.plain)
        }
    }

    private var actionButtonsView: some View {
        HStack {
            Spacer()
            if let url = URL(string: pullRequest.htmlUrl) {
                Link(destination: url) {
                    Label("Open on Browser", systemImage: "safari.fill")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
            }
        }
    }
}

// Helper View for centered messages (like "No description")
struct CenteredContentMessage: View {
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
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
