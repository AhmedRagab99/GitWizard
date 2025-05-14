import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    let onStage: (Chunk) -> Void
    let onUnstage: (Chunk) -> Void
    let onReset: (Chunk) -> Void

    @State private var expandedChunks: Set<String> = []
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(fileDiff.chunks) { chunk in
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
                                diffLineView(line: line)
                            }
                        }
                    }
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
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
            HStack(spacing: 8) {
                Button(action: { onStage(chunk) }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                Button(action: { onUnstage(chunk) }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                Button(action: { onReset(chunk) }) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
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
        }
    }

    private func lineBackground(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.10)
        case .removed: return Color.red.opacity(0.10)
        case .header: return Color.blue.opacity(0.07)
        case .unchanged: return Color.clear
        }
    }
}

//#Preview {
//    FileDiffView(
//        fileDiff: FileDiff(
//            header: "diff --git a/File.swift b/File.swift",
//            extendedHeaderLines: [],
//            fromFileToFileLines: [],
//            chunks: [
//                Chunk(
//                    header: "@@ -1,5 +1,5 @@",
//                    oldLines: ["-old line 1", " old line 2", "-old line 3"],
//                    newLines: ["+new line 1", " old line 2", "+new line 3"]
//                )
//            ],
//            raw: ""
//        ),
//        onStage: { _ in },
//        onUnstage: { _ in },
//        onReset: { _ in }
//    )
//    .frame(width: 800, height: 600)
//}
