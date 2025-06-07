import SwiftUI

struct PullRequestFileView: View {
    let file: PullRequestFile
    @Bindable var viewModel: PullRequestViewModel
    let prCommitId: String
    let comments: [PullRequestComment]
    @State private var showDiff: Bool = true // Show diff by default
    @State private var parsedChunks: [Chunk] = []
    @State private var parseState: ParseState = .idle

    enum ParseState {
        case idle
        case parsing
        case parsed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            fileHeaderView

            if showDiff {
                diffContentView
            }
        }
        .padding(.vertical, 8)
        .task(id: file.patch) {
            // This task runs when the view appears or the patch content changes.
            if showDiff && parsedChunks.isEmpty && parseState == .idle {
                parsePatch()
            }
        }
    }

    private var fileHeaderView: some View {
        HStack(alignment: .center, spacing: 10) {
            statusIcon(for: file.fileStatus)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(file.filename)

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
            .padding(.trailing, file.patch != nil ? 0 : 8)

            if file.patch != nil && !file.patch!.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDiff.toggle()
                    }
                    if showDiff && parsedChunks.isEmpty && parseState == .idle {
                        parsePatch()
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
        switch diffContentState {
        case .loading:
            ProgressView("Loading diff...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        case .noDiff:
            Text("No textual diff available for this file.")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        case .hasDiff:
            DiffView(
                chunks: parsedChunks,
                file: file,
                prCommitId: prCommitId,
                viewModel: viewModel,
                comments: comments
            )
        }
    }

    private enum DiffContentState {
        case loading
        case noDiff
        case hasDiff
    }

    private var diffContentState: DiffContentState {
        if parseState == .parsing {
            return .loading
        } else if !parsedChunks.isEmpty {
            return .hasDiff
        } else {
            return .noDiff
        }
    }

    private func parsePatch() {
        parseState = .parsing
        DispatchQueue.global(qos: .userInitiated).async {
            guard let patchString = file.patch, !patchString.isEmpty else {
                DispatchQueue.main.async {
                    self.parsedChunks = []
                    self.parseState = .parsed
                }
                return
            }

            let lines = patchString.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
            let rawChunkStrings = extractRawChunkStrings(from: lines)
            let chunks = rawChunkStrings.compactMap { Chunk(raw: $0) }

            DispatchQueue.main.async {
                self.parsedChunks = chunks
                self.parseState = .parsed
            }
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
            Image(systemName: "plus.circle.fill").foregroundColor(.green).help("Added")
        case .modified:
            Image(systemName: "pencil.circle.fill").foregroundColor(.orange).help("Modified")
        case .removed:
            Image(systemName: "minus.circle.fill").foregroundColor(.red).help("Removed")
        case .renamed:
            Image(systemName: "arrow.right.circle.fill").foregroundColor(.blue).help("Renamed")
        default:
            Image(systemName: "doc.circle.fill").foregroundColor(.gray).help("Status: \(file.status.capitalized)")
        }
    }
}

// New, separated view for the complex diff content
struct DiffView: View {
    let chunks: [Chunk]
    let file: PullRequestFile
    let prCommitId: String
    var viewModel: PullRequestViewModel
    var comments: [PullRequestComment]

    // Pre-calculates a lookup dictionary for comments by line number for efficiency.
    private var commentsByLine: [Int: [PullRequestComment]] {
        Dictionary(grouping: comments) { $0.line ?? 0 }
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(chunks) { chunk in
                    ForEach(chunk.lines) { line in
                        // Check if there are any comments for this specific line and render them ABOVE the line.
                        if let lineComments = commentsByLine[line.toFileLineNumber ?? 0], !lineComments.isEmpty {
                            ForEach(lineComments) { comment in
                                InlineCommentView(comment: comment)
                                    .padding(.leading, 40) // Indent comments for clarity
                                    .padding(.vertical, 4)
                            }
                        }

                        // Render the actual line of code from the diff.
                        DiffLineView(
                            line: line,
                            file: file,
                            prCommitId: prCommitId,
                            viewModel: viewModel
                        )
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
// Preview code can be added here if needed.
#endif
