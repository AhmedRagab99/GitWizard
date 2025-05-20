import SwiftUI

struct StatusBadge: View {
    let status: FileStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(.white)
            .background(status.color)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if status == .conflict {
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: 1)
                    }
                }
            )
            .shadow(color: status == .conflict ? status.color.opacity(0.5) : .clear,
                    radius: status == .conflict ? 3 : 0)
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadge(status: .added)
        StatusBadge(status: .modified)
        StatusBadge(status: .deleted)
        StatusBadge(status: .conflict)
    }
    .padding()
}
