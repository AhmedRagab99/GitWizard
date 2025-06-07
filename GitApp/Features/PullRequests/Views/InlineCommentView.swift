import SwiftUI

struct InlineCommentView: View {
    let comment: PullRequestComment

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: URL(string:comment.user.avatarUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.circle.fill")
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.login).fontWeight(.bold)
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Text(comment.body)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
        )
        .padding(.leading, 68) // Indent to align with code content
        .padding(.vertical, 4)
    }
}
