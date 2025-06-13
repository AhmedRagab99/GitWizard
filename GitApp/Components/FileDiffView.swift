import SwiftUI


func conflictBackground(_ line: Line) -> Color {
   switch line.kind {
   case .conflictOurs: return Color.blue.opacity(0.1)
   case .conflictTheirs: return Color.green.opacity(0.1)
   case .conflictStart, .conflictMiddle, .conflictEnd: return Color.red.opacity(0.1)
   default: return .clear
   }
}

private func conflictTextColor(_ line: Line) -> Color {
    switch line.kind {
    case .conflictOurs: return .blue
    case .conflictTheirs: return .green
    case .conflictStart, .conflictMiddle, .conflictEnd: return .red
    default: return .primary
    }
}

struct FileDiffView: View {
    let fileDiff: FileDiff
    var onStage: ((Chunk) -> Void)?
    var onUnstage: ((Chunk) -> Void)?
    var onReset: ((Chunk) -> Void)?
    var onResolveOurs: ((Chunk) -> Void)?
    var onResolveTheirs: ((Chunk) -> Void)?
    var onMarkResolved: ((Chunk) -> Void)?
    var isStaged: Bool = false

    @State private var expandedChunks: Set<String> = []
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(fileDiff.chunks) { chunk in
                    Card(
                        cornerRadius: 8,
                        padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                    ) {
                        VStack(spacing: 0) {
                            chunkHeader(chunk)
                                .background(Color(.controlBackgroundColor))
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
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 6)
        }
        .background(Color(.windowBackgroundColor))
    }

    private func chunkHeader(_ chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            Image(systemName: expandedChunks.contains(chunk.id) ? "chevron.down" : "chevron.right")
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
            Text(chunk.lines.first?.raw ?? "")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .lineLimit(1)
            Spacer()

            if chunk.hasConflict {
                conflictButtons(for: chunk)
            } else {
                normalButtons(for: chunk)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(chunk.hasConflict ? Color.red.opacity(0.1) : Color(.controlBackgroundColor))
        .cornerRadius(6)
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
                .buttonStyle(.plain)
            }

            if let onResolveTheirs = onResolveTheirs {
                Button(action: { onResolveTheirs(chunk) }) {
                    Label("Their Changes", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            if let onMarkResolved = onMarkResolved {
                Button(action: { onMarkResolved(chunk) }) {
                    Label("Resolved", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func normalButtons(for chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            if !isStaged, let onStage = onStage {
                Button(action: { onStage(chunk) }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            if isStaged, let onUnstage = onUnstage {
                Button(action: { onUnstage(chunk) }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }

            if let onReset = onReset {
                Button(action: { onReset(chunk) }) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func diffLineView(line: Line) -> some View {
        ListRow(
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundColor: lineBackground(line)
        ) {
            HStack(alignment: .top, spacing: 0) {
                if showLineNumbers {
                    Text(line.toFileLineNumber != nil ? String(line.toFileLineNumber!) : "")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                        .font(.system(size: fontSize, design: .monospaced))
                        .padding(.trailing, 4)
                }
                Text(line.raw)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(lineTextColor(line))
                    .padding(.vertical, 1.5)
                Spacer()
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
