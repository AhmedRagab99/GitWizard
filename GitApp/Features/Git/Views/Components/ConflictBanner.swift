import SwiftUI

struct ConflictBanner: View {
    let conflictedFilesCount: Int
    let onAbortMerge: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Merge Conflicts Detected")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("\(conflictedFilesCount) file\(conflictedFilesCount > 1 ? "s" : "") with conflicts. Please resolve them to continue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onAbortMerge()
            } label: {
                Label("Abort Merge", systemImage: "xmark.octagon.fill")
            }
            .controlSize(.large)

        }
        .padding()
        .background(Material.ultraThin)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    ConflictBanner(conflictedFilesCount: 3, onAbortMerge: {})
        .padding()
}
