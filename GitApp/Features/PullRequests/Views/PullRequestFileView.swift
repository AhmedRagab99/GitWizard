import SwiftUI

struct PullRequestFileView: View {
    let file: PullRequestFile
    let viewModel: PullRequestViewModel
    let prCommitId: String
    @State private var showDiff: Bool = false
    @State private var parsedChunks: [Chunk] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            fileHeaderView

            if showDiff {
                diffContentView
            }
        }
        .padding(.vertical, 8) // Consistent vertical padding for the whole view
    }

    private var fileHeaderView: some View {
        HStack(alignment: .center, spacing: 10) {
            statusIcon(for: file.fileStatus)
                .font(.title3) // Slightly larger icon

            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .fontWeight(.medium) // Medium weight for better readability
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(file.filename) // Show full name on hover

                if let previousFilename = file.previousFilename {
                     Text("Renamed from \(previousFilename)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(previousFilename)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Label("\(file.additions)", systemImage: "plus.circle.fill")
                    .font(.callout)
                    .foregroundColor(.green)
                    .help("Additions")
                Label("\(file.deletions)", systemImage: "minus.circle.fill")
                    .font(.callout)
                    .foregroundColor(.red)
                    .help("Deletions")
            }
            .padding(.trailing, file.patch != nil ? 0 : 8) // Add padding if no chevron

            if file.patch != nil && !file.patch!.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { // Add animation
                        showDiff.toggle()
                    }
                    if showDiff && parsedChunks.isEmpty {
                        parsePatch() // Parsing logic remains
                    }
                } label: {
                    Image(systemName: showDiff ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help(showDiff ? "Hide Diff" : "Show Diff")
            }
        }
    }

    @ViewBuilder
    private var diffContentView: some View {
        if parsedChunks.isEmpty && file.patch != nil && !file.patch!.isEmpty {
            ProgressView("Loading diff...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if parsedChunks.isEmpty && (file.patch == nil || file.patch!.isEmpty) {
            Text("No textual diff available for this file (e.g., binary file or no content changes).")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if !parsedChunks.isEmpty {
            DiffView(chunks: parsedChunks, file: file, prCommitId: prCommitId, viewModel: viewModel)
        }
    }

    private func parsePatch() {
        guard let patchString = file.patch, !patchString.isEmpty else {
            self.parsedChunks = []
            return
        }

        let lines = patchString.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let rawChunkStrings = extractRawChunkStrings(from: lines)

        self.parsedChunks = rawChunkStrings.compactMap { rawChunkString in
            return Chunk(raw: rawChunkString)
        }
    }

    private func extractRawChunkStrings(from lines: [String]) -> [String] {
        var chunkStrings: [String] = []
        var currentChunkLines: [String] = []

        for line in lines {
            if line.starts(with: "@@") {
                if !currentChunkLines.isEmpty {
                    chunkStrings.append(currentChunkLines.joined(separator: "\n"))
                }
                currentChunkLines = [line]
            } else if !currentChunkLines.isEmpty {
                currentChunkLines.append(line)
            }
        }
        if !currentChunkLines.isEmpty {
            chunkStrings.append(currentChunkLines.joined(separator: "\n"))
        }
        return chunkStrings
    }

    @ViewBuilder
    private func statusIcon(for status: PullRequestFile.FileStatus) -> some View {
        switch status {
        case .added:
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .help("Added")
        case .modified:
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(.orange)
                .help("Modified")
        case .removed:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
                .help("Removed")
        case .renamed:
            Image(systemName: "arrow.right.circle.fill") // Or arrow.left.arrow.right.circle.fill
                .foregroundColor(.blue)
                .help("Renamed")
        default: // .copied, .changed, .unchanged, .unknown etc.
            Image(systemName: "doc.circle.fill")
                .foregroundColor(.gray)
                .help("Status: \(file.status.capitalized)")
        }
    }
}

// New, separated view for the complex diff content
struct DiffView: View {
    let chunks: [Chunk]
    let file: PullRequestFile
    let prCommitId: String
    var viewModel: PullRequestViewModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(chunks) { chunk in
                    ForEach(chunk.lines) { line in
                        DiffLineView(line: line, file: file, prCommitId: prCommitId,viewModel: viewModel)
                    }
                    if chunk.id != chunks.last?.id {
                         Divider().padding(.vertical, 4)
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .frame(maxHeight: 400)
    }
}

#if DEBUG
// Updated Preview (if needed, requires mock Chunk/Line and updated PullRequestFile)
// ... Preview code would go here ...
#endif
