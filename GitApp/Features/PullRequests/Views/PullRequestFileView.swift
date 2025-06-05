import SwiftUI

struct PullRequestFileView: View {
    let file: PullRequestFile
    @State private var showDiff: Bool = false
    @State private var parsedChunks: [Chunk] = []

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(file.filename)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(file.filename) // Show full name on hover
                    HStack {
                        statusView
                        Spacer()
                        Text("+\(file.additions)")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("-\(file.deletions)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                Spacer()
                if file.patch != nil {
                    Button {
                        showDiff.toggle()
                        if showDiff && parsedChunks.isEmpty {
                            parsePatch()
                        }
                    } label: {
                        Image(systemName: showDiff ? "chevron.up.square.fill" : "chevron.down.square")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showDiff {
                if parsedChunks.isEmpty && file.patch != nil && !file.patch!.isEmpty {
                    // Show a progress view or placeholder if parsing is somehow delayed
                    // or if patch is present but resulted in no chunks (e.g. whitespace changes only, no hunk headers)
                    // However, parsePatch() is synchronous for now.
                    Text("Loading diff...") // Should be replaced by actual diff content quickly
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else if parsedChunks.isEmpty && (file.patch == nil || file.patch!.isEmpty) {
                     Text("No diff available for this file (e.g., binary file or no content changes).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(parsedChunks) { chunk in
                                ForEach(chunk.lines) { line in
                                    DiffLineView(line: line)
                                }
                                if chunk.id != parsedChunks.last?.id {
                                     Divider().padding(.vertical, 2) // Separator between chunks
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .background(Color(.textBackgroundColor)) // Standard background for code blocks
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .frame(maxHeight: 300) // Limit initial height, content can scroll
                    .padding(.top, 6)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func parsePatch() {
        guard let patchString = file.patch, !patchString.isEmpty else {
            self.parsedChunks = []
            return
        }

        let lines = patchString.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let rawChunkStrings = extractRawChunkStrings(from: lines)

        self.parsedChunks = rawChunkStrings.compactMap { rawChunkString in
            // The Chunk initializer expects the raw string for a single chunk.
            // It might throw if the format is unexpected, but here we assume valid patch data.
            return Chunk(raw: rawChunkString) // Assuming Chunk.init doesn't throw or we handle it.
        }
    }

    /// Adapted from FileDiff.extractChunks to work directly with patch strings for PR files.
    private func extractRawChunkStrings(from lines: [String]) -> [String] {
        var chunkStrings: [String] = []
        var currentChunkLines: [String] = []

        for line in lines {
            if line.starts(with: "@@") {
                // If we are already building a chunk, save it before starting a new one.
                if !currentChunkLines.isEmpty {
                    chunkStrings.append(currentChunkLines.joined(separator: "\n"))
                }
                currentChunkLines = [line] // Start new chunk with its header line
            } else if !currentChunkLines.isEmpty { // Only add lines if we are inside a chunk
                currentChunkLines.append(line)
            }
            // Lines before the first "@@" (e.g. git diff header for the file) are ignored for chunk parsing.
        }

        // Append the last chunk if it exists
        if !currentChunkLines.isEmpty {
            chunkStrings.append(currentChunkLines.joined(separator: "\n"))
        }
        return chunkStrings
    }

    @ViewBuilder
    private var statusView: some View {
        Text(file.status.capitalized)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch file.fileStatus { // Using fileStatus from PullRequestFile model
        case .added: return .green
        case .modified: return .orange
        case .removed: return .red
        case .renamed: return .blue
        default: return .gray // .copied, .changed, .unchanged
        }
    }
}

#if DEBUG
//struct PullRequestFileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let samplePatch1 = """
//@@ -21,6 +21,7 @@
//         return会议RoomViewModel(会议室:会议室)
//     }
//
//+    // This is an added line comment.
//     func make会议室DetailView(会议室: MeetingRoom) -> some View {
//         let viewModel = make会议RoomDetailViewModel(会议室:会议室)
//         return会议RoomDetailView(viewModel: viewModel)
//"""
//
//        let samplePatch2 = """
//@@ -1,2 +1,2 @@
//-old line
//+new line
//@@ -10,3 +10,3 @@
// context
//-removed
//+added
//"""
//
//        let file1 = PullRequestFile(sha: "a", filename: "Sources/Coordinator/AppCoordinator.swift", status: "modified", additions: 1, deletions: 0, changes: 1, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: samplePatch1, previousFilename: nil)
//        let file2 = PullRequestFile(sha: "b", filename: "Project.xcscheme", status: "added", additions: 1, deletions: 1, changes: 2, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: samplePatch2, previousFilename: nil)
//        let file3 = PullRequestFile(sha: "c", filename: "Image.png", status: "added", additions: 0, deletions: 0, changes: 0, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: nil, previousFilename: nil) // No patch
//        let file4 = PullRequestFile(sha: "d", filename: "VeryLongFileNameThatShouldBeTruncatedInTheUIWellSeeHowItLooks.txt", status: "renamed", additions: 5, deletions: 2, changes: 7, blobUrl: nil, rawUrl: nil, contentsUrl: nil, patch: samplePatch1, previousFilename: "OldFileName.txt")
//
//
//        return ScrollView {
//            VStack {
//                PullRequestFileView(file: file1)
//                Divider()
//                PullRequestFileView(file: file2)
//                Divider()
//                PullRequestFileView(file: file3)
//                Divider()
//                PullRequestFileView(file: file4)
//            }
//            .padding()
//        }
//        .previewDisplayName("Pull Request File Rows with Diff")
//    }
//}
#endif
