import SwiftUI

struct PullRequestHeaderReviewersView: View {
    var reviewers: [ReviewerStateSummary]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(reviewers) { reviewer in
                    VStack {
                        AsyncImage(url: URL(string: reviewer.user.avatarUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(statusIcon(for: reviewer.state), alignment: .bottomTrailing)

                        Text(reviewer.user.login)
                            .font(.caption)                            
                            .truncationMode(.tail)

                    }
                    .frame(width: 60)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func statusIcon(for state: ReviewerStateSummary.State) -> some View {
        let (iconName, color) = state.iconInfo
        Image(systemName: iconName)
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(4)
            .background(color)
            .clipShape(Circle())
            .offset(x: 4, y: 4)
            .help(state.rawValue)
    }
}

extension ReviewerStateSummary.State {
    var iconInfo: (String, Color) {
        switch self {
        case .approved:
            return ("checkmark", .green)
        case .changesRequested:
            return ("xmark", .red)
        case .commented:
            return ("bubble.left.fill", .gray)
        case .unknown:
            return ("questionmark", .orange)
        }
    }
}
