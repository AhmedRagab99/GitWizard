import SwiftUI

/// A compact view for showing blame information at the end of a line
struct LineBlameView: View {
    let author: String
    let commitHash: String
    let date: Date
    let onTap: () -> Void

    @State private var isHovered = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Generate a consistent color based on author name
    private func authorColor(_ author: String) -> Color {
        let hash = author.utf8.reduce(0) { $0 + Int($1) }
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .yellow, .mint, .teal, .indigo]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        HStack(spacing: 4) {
            // Author indicator dot with color coding
            Circle()
                .fill(authorColor(author))
                .frame(width: 6, height: 6)

            // Short commit hash
            Text(String(commitHash.prefix(7)))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .popover(isPresented: $isHovered) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(author)
                        .font(.headline)
                    Spacer()
                    Circle()
                        .fill(authorColor(author))
                        .frame(width: 10, height: 10)
                }

                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(commitHash)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.top, 2)

                Text("Click to view commit")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
            .padding(8)
            .frame(width: 200)
        }
    }
}

#Preview {
    HStack {
        Spacer()
        LineBlameView(
            author: "John Doe",
            commitHash: "abc1234def5678",
            date: Date(),
            onTap: {}
        )
    }
    .padding()
}
