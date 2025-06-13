import SwiftUI

struct CenteredContentMessage: View {
    let systemImage: String
    var title: String?
    let message: String
    var color: Color = .secondary
    var imageSize: CGFloat = 36

    init(systemImage: String, title: String? = nil, message: String, color: Color = .secondary, imageSize: CGFloat = 36) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.color = color
        self.imageSize = imageSize
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: imageSize))
                .foregroundColor(color)

            if let title = title {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack {
        CenteredContentMessage(
            systemImage: "exclamationmark.triangle.fill",
            title: "No Connection",
            message: "Please check your internet connection and try again.",
            color: .orange
        )

        CenteredContentMessage(
            systemImage: "text.alignleft",
            message: "No description provided."
        )
    }
}
