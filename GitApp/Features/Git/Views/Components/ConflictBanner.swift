import SwiftUI

struct ConflictBanner: View {
    let conflictedFilesCount: Int
    let onAbortMerge: () -> Void

    var body: some View {
        HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Merge Conflict")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("\(conflictedFilesCount) file\(conflictedFilesCount > 1 ? "s" : "") with conflicts")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Button {
                onAbortMerge()
            } label: {
                Label("Abort Merge", systemImage: "xmark.octagon.fill")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.5))
            .controlSize(.large)
            .help("Abort the current merge process (git merge --abort)")
        }
        .padding()
        .background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ConflictBanner(conflictedFilesCount: 2, onAbortMerge: {})
    .padding()
}
