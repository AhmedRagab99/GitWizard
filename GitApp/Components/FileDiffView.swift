import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    var onStage: ((Chunk) -> Void)?
    var onUnstage: ((Chunk) -> Void)?
    var onReset: ((Chunk) -> Void)?
    var onResolveOurs: ((Chunk) -> Void)?
    var onResolveTheirs: ((Chunk) -> Void)?
    var onMarkResolved: ((Chunk) -> Void)?
    var isStaged: Bool = false
    var title: String? = nil
    var blameInfo: [Int: BlameLine]? = nil
    var onBlameSelected: ((String) -> Void)? = nil
    var showBlameInfo: Bool = false

    @State private var expandedChunks: Set<String> = []
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true


    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                // Optional title
                if let title = title {
                    HStack {
                        Text(title)
                            .font(.headline)

                        Spacer()

                        // Toggle for showing/hiding blame
                        if blameInfo != nil {
                            Toggle(isOn: .constant(showBlameInfo)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.text.rectangle")
                                        .imageScale(.small)

                                    Text("Blame")
                                        .font(.caption)
                                }
                            }
                            .toggleStyle(.button)
                            .buttonStyle(.bordered)
                            .disabled(true) // This is just for display, actual toggling happens in parent view
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                // Chunks
                ForEach(fileDiff.chunks) { chunk in
                    Card(
                        backgroundColor: chunk.hasConflict ? Color.red.opacity(0.05) : Color(.controlBackgroundColor).opacity(0.8),
                        cornerRadius: 8,
                        shadowRadius: 1,
                        padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                    ) {
                        LazyVStack(spacing: 0) {
                            chunkHeader(chunk)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        if expandedChunks.contains(chunk.id) {
                                            expandedChunks.remove(chunk.id)
                                        } else {
                                            expandedChunks.insert(chunk.id)
                                        }
                                    }
                                }
                            if expandedChunks.contains(chunk.id) {
                                VStack(spacing: 0) {
                                    ForEach(chunk.lines) { line in
                                        if line.kind == .conflictStart || line.kind == .conflictMiddle || line.kind == .conflictEnd ||
                                           line.kind == .conflictOurs || line.kind == .conflictTheirs {
                                            ConflictLineView(line: line)
                                        } else {
                                            diffLineView(line: line)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }

                // No changes indicator
                if fileDiff.chunks.isEmpty {
                    CenteredContentMessage(
                        systemImage: "doc.text",
                        title: fileDiff.displayFileName.isEmpty ? "No File Selected" : fileDiff.displayFileName,
                        message: fileDiff.status == .added ? "New file" : "No changes to display",
                        color: fileDiff.status == .added ? .green : .secondary
                    )
                    .padding(.top, 30)
                }
            }
            .padding(.vertical, 6)
        }
        .background(Color(.windowBackgroundColor))
        .onFirstAppear {
            // Expand the first chunk by default if there's only one
            if fileDiff.chunks.count == 1, let chunkId = fileDiff.chunks.first?.id {
                expandedChunks.insert(chunkId)
            }
        }
    }

    private func chunkHeader(_ chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            Image(systemName: expandedChunks.contains(chunk.id) ? "chevron.down" : "chevron.right")
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)

            if chunk.hasConflict {
                TagView(
                    text: "Conflict",
                    color: .red,
                    systemImage: "exclamationmark.triangle"
                )
            }

            Text(chunk.lines.first?.raw ?? "")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(chunk.hasConflict ? .red : .blue)
                .lineLimit(1)

            Spacer()

            if chunk.hasConflict {
                conflictButtons(for: chunk)
            } else {
                normalButtons(for: chunk)
            }
        }

        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func conflictButtons(for chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            if let onResolveOurs = onResolveOurs {
                Button(action: { onResolveOurs(chunk) }) {
                    Label("Our Changes", systemImage: "arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
            }

            if let onResolveTheirs = onResolveTheirs {
                Button(action: { onResolveTheirs(chunk) }) {
                    Label("Their Changes", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
            }

            if let onMarkResolved = onMarkResolved {
                Button(action: { onMarkResolved(chunk) }) {
                    Label("Resolved", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func normalButtons(for chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            if !isStaged, let onStage = onStage {
                Button(action: { onStage(chunk) }) {
                    Label("Stage", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
            }

            if isStaged, let onUnstage = onUnstage {
                Button(action: { onUnstage(chunk) }) {
                    Label("Unstage", systemImage: "minus.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.bordered)
            }

            if let onReset = onReset {
                Button(action: { onReset(chunk) }) {
                    Label("Reset", systemImage: "arrow.uturn.backward.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func diffLineView(line: Line) -> some View {
        ListRow(
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundColor: .clear,
            cornerRadius: 0,
            shadowRadius: 0
        ) {
            HStack(alignment: .top, spacing: 0) {
                if showLineNumbers {
                    Text(line.toFileLineNumber != nil ? String(line.toFileLineNumber!) : "")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                        .font(.system(size: fontSize, design: .monospaced))
                        .padding(.trailing, 4)
                }

                // Line content
                Text(line.raw)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(lineTextColor(line))
                    .padding(.vertical, 1.5)

                Spacer()

                // Show blame information if available and enabled
                if showBlameInfo,
                   let lineNumber = line.toFileLineNumber,
                   let blame = blameInfo?[lineNumber] {
                    LineBlameView(
                        author: blame.author,
                        commitHash: blame.commitHash,
                        date: blame.date,
                        onTap: {
                            onBlameSelected?(blame.commitHash)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func lineTextColor(_ line: Line) -> Color {
        switch line.kind {
        case .added: return .green
        case .removed: return .red
        case .unchanged: return .primary
        default: return .primary
        }
    }

    private func lineBackground(_ line: Line) -> Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.1)
        case .removed: return Color.red.opacity(0.1)
        case .unchanged: return .clear
        default: return .clear
        }
    }
}

#if DEBUG
// Preview for FileDiffView
struct FileDiffView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Example 1: A file with chunks
                FileDiffView(
                    fileDiff: exampleFileDiffWithChunks,
                    onStage: { _ in },
                    onReset: { _ in }
                )
                .frame(height: 300)

                // Example 2: A conflict file
                FileDiffView(
                    fileDiff: exampleConflictFileDiff,
                    onResolveOurs: { _ in },
                    onResolveTheirs: { _ in },
                    onMarkResolved: { _ in }
                )
                .frame(height: 300)

                // Example 3: An empty file
                FileDiffView(
                    fileDiff: exampleEmptyFileDiff
                )
                .frame(height: 200)
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }

    // Sample file diff with changes
    static var exampleFileDiffWithChunks: FileDiff {
        let rawDiff = """
        diff --git a/Example.swift b/Example.swift
        index 1234567..7654321 100644
        --- a/Example.swift
        +++ b/Example.swift
        @@ -1,5 +1,6 @@
        import SwiftUI

        -func oldFunction() {
        -    print("Old implementation")
        +func newFunction() {
        +    // New implementation
        +    print("Better implementation")
        }
        """
        do {
            return try FileDiff(raw: rawDiff)
        } catch {
            return FileDiff(untrackedFile: "Example.swift")
        }
    }

    // Sample file diff with conflict
    static var exampleConflictFileDiff: FileDiff {
        var diff = FileDiff(untrackedFile: "ConflictExample.swift")
        diff.status = .conflict
        return diff
    }

    // Empty file diff
    static var exampleEmptyFileDiff: FileDiff {
        FileDiff(untrackedFile: "")
    }
}
#endif
