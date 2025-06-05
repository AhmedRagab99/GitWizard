import SwiftUI

struct PullRequestCommentView: View {
    let comment: PullRequestComment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Consider using AsyncImage for avatars if targeting iOS 15+
                // AsyncImage(url: URL(string: comment.user.avatarUrl ?? "")) {
                //     $0.resizable().aspectRatio(contentMode: .fill)
                // } placeholder: {
                //     Image(systemName: "person.circle.fill")
                // }
                // .frame(width: 30, height: 30)
                // .clipShape(Circle())

                Text(comment.user.login)
                    .fontWeight(.semibold)
                Text("commented \(comment.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let url = URL(string: comment.htmlUrl ?? "") {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.caption)
                }
            }

            // TODO: Add Markdown rendering for the comment body if desired
            // For now, simple Text view
            Text(comment.body)
                .font(.body)
        }
        .padding(.vertical, 8)
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
