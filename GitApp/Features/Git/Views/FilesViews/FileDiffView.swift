import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    let onStage: (Chunk) -> Void
    let onUnstage: (Chunk) -> Void
    let onReset: (Chunk) -> Void
    var onResolveOurs: ((Chunk) -> Void)?
    var onResolveTheirs: ((Chunk) -> Void)?
    var onMarkResolved: ((Chunk) -> Void)?
    var isStaged: Bool = false

    @State private var expandedChunks: Set<String> = []
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true
    @State private var operationInProgress: Bool = false
    @State private var operatedChunks: Set<String> = []


    var body: some View {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(fileDiff.chunks) { chunk in
                            VStack(spacing: 0) {
                                chunkHeader(chunk)
                                    .background(Color(.controlBackgroundColor))
                                    .opacity(operationInProgress && operatedChunks.contains(chunk.id) ? 0.6 : 1.0)
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
                                            ConflictLineView(line: line, isSelected: false, onSelect: {})
                                        } else {
                                            diffLineView(line: line)
                                        }
                                    }
                                }
                            }
                            .background(Color(.windowBackgroundColor))
                            .cornerRadius(8)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(operatedChunks.contains(chunk.id) ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                    .opacity(operatedChunks.contains(chunk.id) ? 1.0 : 0.0)
                            )
                            .animation(.easeInOut(duration: 0.2), value: operatedChunks.contains(chunk.id))
                        }
                    }
                    .padding(.vertical, 6)
                }
            
        
        .background(Color(.windowBackgroundColor))
        .onChange(of: fileDiff.id) {
            operatedChunks.removeAll()
            
            loadFileContent()
        }
        .onAppear {
            loadFileContent()
        }
    }

    private func loadFileContent() {
        let fileContent = fileDiff.chunks.flatMap { chunk in
            chunk.lines.compactMap { line in
                if line.kind == .header {
                    return nil
                }

                if line.kind == .added || line.kind == .removed || line.kind == .unchanged {
                    if line.raw.count > 1 {
                        return String(line.raw.dropFirst())
                    } else {
                        return ""
                    }
                }

                return line.raw
            }
        }.joined(separator: "\n")

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
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }

    @ViewBuilder
    private func conflictButtons(for chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                performOperation {
                    operatedChunks.insert(chunk.id)
                    onResolveOurs?(chunk)
                }
            }) {
                Label("Our Changes", systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .disabled(operationInProgress)

            Button(action: {
                performOperation {
                    operatedChunks.insert(chunk.id)
                    onResolveTheirs?(chunk)
                }
            }) {
                Label("Their Changes", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
            .disabled(operationInProgress)

            Button(action: {
                performOperation {
                    operatedChunks.insert(chunk.id)
                    onMarkResolved?(chunk)
                }
            }) {
                Label("Resolved", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .disabled(operationInProgress)
        }
    }

    @ViewBuilder
    private func normalButtons(for chunk: Chunk) -> some View {
        HStack(spacing: 8) {
            if !isStaged {
                Button(action: {
                    performOperation {
                        operatedChunks.insert(chunk.id)
                        onStage(chunk)
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(operationInProgress)
            }

            if isStaged {
                Button(action: {
                    performOperation {
                        operatedChunks.insert(chunk.id)
                        onUnstage(chunk)
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .disabled(operationInProgress)
            }

            Button(action: {
                performOperation {
                    operatedChunks.insert(chunk.id)
                    onReset(chunk)
                }
            }) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .disabled(operationInProgress)
        }
    }

    private func performOperation(operation: @escaping () -> Void) {
        operationInProgress = true

        operatedChunks.removeAll()

        operation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            operationInProgress = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                operatedChunks.removeAll()
            }
        }
    }

    private func diffLineView(line: Chunk.Line) -> some View {
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
        .background(lineBackground(line))
        .contentShape(Rectangle())
    }

    private func lineTextColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .added: return .green
        case .removed: return .red
        case .unchanged: return .primary
        case .header: return .blue
        case .conflictStart, .conflictEnd: return .red
        case .conflictMiddle: return .orange
        case .conflictOurs: return .blue
        case .conflictTheirs: return .green
        }
    }

    private func lineBackground(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.10)
        case .removed: return Color.red.opacity(0.10)
        case .header: return Color.blue.opacity(0.07)
        case .unchanged: return Color.clear
        case .conflictStart, .conflictEnd: return Color.red.opacity(0.1)
        case .conflictMiddle: return Color.orange.opacity(0.1)
        case .conflictOurs: return Color.blue.opacity(0.1)
        case .conflictTheirs: return Color.green.opacity(0.1)
        }
    }
}
