import SwiftUI

struct PullRequestReviewView: View {
    let review: PullRequestReview

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url:  URL(string:review.user.avatarUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.user.login).fontWeight(.bold)
                    Spacer()
                    if let submittedAt = review.submittedAt {
                        Text(submittedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                statusBadge

                if let body = review.body, !body.isEmpty {
                    Text(body)
                        .padding(.top, 4)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (text, color, icon) = statusInfo(for: review.state)
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(color)
            .clipShape(Capsule())
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
