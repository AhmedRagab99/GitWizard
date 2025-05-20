import SwiftUI

struct ConflictBanner: View {
    let conflictedFiles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Merge conflicts detected")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                Text("Resolve conflicts to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(conflictedFilesDisplayText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondaryLabelColor).opacity(0.9))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red, lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top)
    }

    // Break down complex expression into a computed property
    private var conflictedFilesDisplayText: String {
        let fileNames = conflictedFiles.map { path in
            path.components(separatedBy: "/").last ?? path
        }
        return "Conflicted files: \(fileNames.joined(separator: ", "))"
    }
}

#Preview {
    ConflictBanner(conflictedFiles: [
        "path/to/file1.swift",
        "another/path/file2.swift"
    ])
    .padding()
}
