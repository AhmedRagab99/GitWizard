import SwiftUI

struct PullRequestFileView: View {
    let file: PullRequestFile
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
            ProgressView("Loading diff...") // Keep progress view for parsing
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if parsedChunks.isEmpty && (file.patch == nil || file.patch!.isEmpty) {
            Text("No textual diff available for this file (e.g., binary file or no content changes).")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if !parsedChunks.isEmpty {
            // Using a Group to avoid re-applying modifiers if not needed
            // The existing ScrollView and LazyVStack for diff lines seems reasonable.
            // Enhancements here would primarily be within DiffLineView itself or its data.
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(parsedChunks) { chunk in
                        // Optional: Add chunk header display if desired (e.g., `Text(chunk.header)`)
                        // styled appropriately, e.g., .font(.caption.monospaced()).foregroundColor(.gray)
                        ForEach(chunk.lines) { line in
                            DiffLineView(line: line) // Relies on DiffLineView for line styling
                        }
                        if chunk.id != parsedChunks.last?.id {
                             Divider().padding(.vertical, 4) // Slightly more padding for chunk separator
                        }
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)) // Adjusted padding
                .background(Color(nsColor: .textBackgroundColor)) // System background for code
                .cornerRadius(8) // Slightly larger radius
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1) // Slightly more visible border
                )
            }
            .frame(maxHeight: 400) // Increased max height slightly
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

#if DEBUG
// Updated Preview (if needed, requires mock Chunk/Line and updated PullRequestFile)
// ... Preview code would go here ...
#endif
