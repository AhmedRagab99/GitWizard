import SwiftUI

struct Card<Content: View>: View {
    var title: String?
    let content: Content
    var backgroundColor: Color = Color(.controlBackgroundColor)
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 2
    var padding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)

    init(title: String? = nil,
         backgroundColor: Color = Color(.controlBackgroundColor),
         cornerRadius: CGFloat = 12,
         shadowRadius: CGFloat = 2,
         padding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14),
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            content
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: shadowRadius, x: 0, y: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        Card(title: "Repository Information") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Main Branch: main")
                Text("Last Commit: 2d ago")
                Text("Status: Clean")
            }
        }

        Card {
            VStack {
                Text("Card without title")
                    .font(.body)
                Button("Action") { }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
    .padding()
    .frame(width: 300)
}
