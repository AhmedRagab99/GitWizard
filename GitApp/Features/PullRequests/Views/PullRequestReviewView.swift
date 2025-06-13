import SwiftUI

struct PullRequestReviewView: View {
    let review: PullRequestReview

    var body: some View {
        Card(cornerRadius: 8, shadowRadius: 1) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar placeholder
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(review.user.login.prefix(1).uppercased())
                            .font(.headline.bold())
                            .foregroundColor(.accentColor)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(review.user.login)
                            .fontWeight(.bold)

                        Spacer()

                        if let submittedAt = review.submittedAt {
                            Text(submittedAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    let (text, color, icon) = statusInfo(for: review.state)
                    TagView(
                        text: text,
                        color: color,
                        systemImage: icon
                    )

                    if let body = review.body, !body.isEmpty {
                        Text(body)
                            .padding(.top, 4)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func statusInfo(for state: String) -> (String, Color, String) {
        switch state.uppercased() {
        case "APPROVED":
            return ("Approved", .green, "checkmark.circle.fill")
        case "CHANGES_REQUESTED":
            return ("Changes Requested", .red, "xmark.circle.fill")
        case "COMMENTED":
            return ("Commented", .gray, "bubble.left.fill")
        default:
            return (state.capitalized, .orange, "questionmark.circle.fill")
        }
    }
}
