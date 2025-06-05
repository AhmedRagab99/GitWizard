import SwiftUI

struct PullRequestRow: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pullRequest.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text("#\(pullRequest.number)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: pullRequest.prStatusIconName)
                    .foregroundColor(pullRequest.prStatusColor)
                Text(pullRequest.prState.displayName)
                    .font(.caption)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(pullRequest.prStatusColor.opacity(0.2))
                    .cornerRadius(4)

                Text("by \(pullRequest.user.login) · \(pullRequest.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let body = pullRequest.body, !body.isEmpty {
                 Text(body)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 6)
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
