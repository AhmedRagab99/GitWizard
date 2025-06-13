import SwiftUI

struct PullRequestCommentView: View {
    let comment: PullRequestComment

    var body: some View {
        Card(cornerRadius: 8, shadowRadius: 1) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    // User avatar icon
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(comment.user.login.prefix(1).uppercased())
                                .font(.caption.bold())
                                .foregroundColor(.accentColor)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(comment.user.login)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("commented \(comment.createdAt, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let url = URL(string: comment.htmlUrl ?? "") {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }

                // Comment content
                Text(comment.body)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 2)
        }
    }
}

#if DEBUG
//struct PullRequestCommentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let author = PullRequestAuthor(id: 1, login: "devUser", avatarUrl: "", htmlUrl: "https://github.com/devUser")
//        let sampleComment = PullRequestComment(
//            id: 101,
//            user: author,
//            body: "This is a thoughtful comment on the pull request. It contains some **markdown** and mentions @anotherUser.",
//            createdAt: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
//            updatedAt: Date().addingTimeInterval(-3600 * 1),  // 1 hour ago
//            htmlUrl: "https://github.com/octocat/Hello-World/pull/1#issuecomment-101"
//        )
//
//        return List { // Embed in List for typical row appearance
//            PullRequestCommentView(comment: sampleComment)
//        }
//        .previewLayout(.sizeThatFits)
//        .padding()
//        .previewDisplayName("Pull Request Comment Row")
//    }
//}
#endif
