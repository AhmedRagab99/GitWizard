import SwiftUI

struct PullRequestRow: View {
    let pullRequest: PullRequest
    var onView: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onReopen: (() -> Void)? = nil

    var body: some View {
        ListRow(
            padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14),
            onTap: onView,
            cornerRadius: 8,
            shadowRadius: 1
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: pullRequest.prStatusIconName)
                        .font(.system(size: 18))
                        .foregroundColor(pullRequest.prStatusColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pullRequest.title)
                            .font(.headline)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            TagView(
                                text: pullRequest.prState.displayName,
                                color: pullRequest.prStatusColor,
                                systemImage: pullRequest.prStatusIconName
                            )

                            Text("#\(pullRequest.number)")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            Text("by \(pullRequest.user.login) · \(pullRequest.createdAt, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Comment count badge is removed since the PullRequest model doesn't have a comments property
                }

                if let body = pullRequest.body, !body.isEmpty {
                     Text(body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.leading, 26) // Align with the title for better visual hierarchy
                }
            }
        }
        .withContextMenu(type: createContextMenuType())
    }

    private func createContextMenuType() -> ContextMenuItems.MenuType {
        if let onView = onView {
            let canClose = pullRequest.prState == .open && onClose != nil
            let canReopen = pullRequest.prState == .closed && pullRequest.mergedAt == nil && onReopen != nil

            return .pullRequest(
                onView: onView,
                onClose: canClose ? onClose : nil,
                onReopen: canReopen ? onReopen : nil
            )
        } else {
            // If no actions are available, provide at least a copy option
            return .custom(items: [
                ContextMenuItems.MenuItem(label: "Copy PR Number", icon: "doc.on.clipboard", action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("#\(pullRequest.number)", forType: .string)
                }),
                ContextMenuItems.MenuItem(label: "Copy PR URL", icon: "link", action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(pullRequest.htmlUrl, forType: .string)
                })
            ])
        }
    }
}

#if DEBUG
//struct PullRequestRow_Previews: PreviewProvider {
//    static var previews: some View {
//        // Sample PullRequestAuthor
//        let author = PullRequestAuthor(id: 1, login: "octocat", avatarUrl: "https://avatars.githubusercontent.com/u/583231?v=4", htmlUrl: "https://github.com/octocat")
//
//        // Sample PullRequest for preview
//        let samplePR = PullRequest(
//            id: 1,
//            number: 123,
//            title: "Amazing New Feature That Will Change The World As We Know It Today",
//            user: author,
//            state: "open", // This will be mapped by prState
//            body: "This pull request introduces an incredible new feature. It does many things and fixes several bugs. It also includes extensive tests and documentation to ensure everything works perfectly.",
//            createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
//            updatedAt: Date().addingTimeInterval(-86400 * 1), // 1 day ago
//            closedAt: nil,
//            mergedAt: nil,
//            htmlUrl: "https://github.com/octocat/Hello-World/pull/123",
//            diffUrl: "https://github.com/octocat/Hello-World/pull/123.diff",
//            patchUrl: "https://github.com/octocat/Hello-World/pull/123.patch",
//            commentsUrl: "https://api.github.com/repos/octocat/Hello-World/issues/123/comments"
//        )
//
//        let mergedPR = PullRequest(
//            id: 2,
//            number: 124,
//            title: "Important Bug Fix",
//            user: author,
//            state: "closed",
//            body: "This PR fixes a critical bug.",
//            createdAt: Date().addingTimeInterval(-86400 * 5),
//            updatedAt: Date().addingTimeInterval(-86400 * 3),
//            closedAt: Date().addingTimeInterval(-86400 * 3),
//            mergedAt: Date().addingTimeInterval(-86400 * 3), // Indicates merged
//            htmlUrl: "https://github.com/octocat/Hello-World/pull/124",
//            diffUrl: "https://github.com/octocat/Hello-World/pull/124.diff",
//            patchUrl: "https://github.com/octocat/Hello-World/pull/124.patch",
//            commentsUrl: "https://api.github.com/repos/octocat/Hello-World/issues/124/comments"
//        )
//
//        return Group {
//            PullRequestRow(pullRequest: samplePR)
//                .previewLayout(.sizeThatFits)
//                .padding()
//
//            PullRequestRow(pullRequest: mergedPR)
//                .previewLayout(.sizeThatFits)
//                .padding()
//        }
//        .previewDisplayName("Pull Request Row")
//    }
//}
#endif
